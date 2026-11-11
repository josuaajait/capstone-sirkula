<?php

namespace App\Services;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Mengirim notifikasi push lewat Firebase Cloud Messaging (API HTTP v1).
 *
 * Aktif hanya jika FCM_CREDENTIALS di .env menunjuk ke file kunci service
 * account Firebase (JSON). Tanpa itu, kelas ini tidak melakukan apa-apa dan
 * notifikasi tetap tersimpan di aplikasi seperti biasa.
 */
class FcmSender
{
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    /** @return array{project_id: string, client_email: string, private_key: string, token_uri?: string}|null */
    public function credentials(): ?array
    {
        $path = config('services.fcm.credentials');
        if (! $path) {
            return null;
        }
        if (! str_starts_with($path, '/') && ! preg_match('/^[A-Za-z]:[\\\\\/]/', $path)) {
            $path = base_path($path);
        }
        if (! is_file($path)) {
            return null;
        }
        $json = json_decode((string) file_get_contents($path), true);

        return isset($json['project_id'], $json['client_email'], $json['private_key']) ? $json : null;
    }

    public function enabled(): bool
    {
        return $this->credentials() !== null;
    }

    /** Kirim ke semua HP milik $user. Galat jaringan dicatat, tidak dilempar. */
    public function sendToUser(User $user, string $title, string $body, array $data = []): int
    {
        $creds = $this->credentials();
        if (! $creds) {
            return 0;
        }
        $tokens = DeviceToken::where('user_id', $user->id)->pluck('token');
        if ($tokens->isEmpty()) {
            return 0;
        }

        try {
            $access = $this->accessToken($creds);
        } catch (Throwable $e) {
            Log::warning('FCM: gagal mengambil token akses', ['error' => $e->getMessage()]);

            return 0;
        }

        $sent = 0;
        $url = "https://fcm.googleapis.com/v1/projects/{$creds['project_id']}/messages:send";
        foreach ($tokens as $token) {
            $response = Http::withToken($access)->timeout(5)->post($url, [
                'message' => [
                    'token' => $token,
                    'notification' => ['title' => $title, 'body' => $body],
                    'data' => array_map('strval', $data),
                    'android' => [
                        'priority' => 'high',
                        'notification' => ['channel_id' => 'sirkula', 'sound' => 'default'],
                    ],
                ],
            ]);
            if ($response->successful()) {
                $sent++;
            } elseif ($response->status() === 404 || str_contains($response->body(), 'UNREGISTERED')) {
                // HP sudah menghapus aplikasi atau token kedaluwarsa.
                DeviceToken::where('token', $token)->delete();
            } else {
                Log::warning('FCM: pengiriman gagal', ['status' => $response->status(), 'body' => $response->body()]);
            }
        }

        return $sent;
    }

    /** Token akses OAuth dari kunci service account, disimpan 50 menit. */
    private function accessToken(array $creds): string
    {
        return Cache::remember('fcm.access_token.'.md5($creds['client_email']), 3000, function () use ($creds) {
            $now = time();
            $tokenUri = $creds['token_uri'] ?? 'https://oauth2.googleapis.com/token';
            $segments = [
                $this->base64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT'])),
                $this->base64url(json_encode([
                    'iss' => $creds['client_email'],
                    'scope' => self::SCOPE,
                    'aud' => $tokenUri,
                    'iat' => $now,
                    'exp' => $now + 3600,
                ])),
            ];
            $signature = '';
            if (! openssl_sign(implode('.', $segments), $signature, $creds['private_key'], OPENSSL_ALGO_SHA256)) {
                throw new \RuntimeException('Kunci service account tidak valid.');
            }
            $segments[] = $this->base64url($signature);

            return Http::asForm()->timeout(5)->post($tokenUri, [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => implode('.', $segments),
            ])->throw()->json('access_token');
        });
    }

    private function base64url(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
