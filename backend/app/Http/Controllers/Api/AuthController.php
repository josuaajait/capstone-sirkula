<?php

namespace App\Http\Controllers\Api;

use App\Enums\Role;
use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\Notifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

/** Akses (FR-A2 sampai FR-A5). */
class AuthController extends Controller
{
    /** Kode verifikasi berlaku 15 menit. */
    private const RESET_TTL_MINUTES = 15;

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'login' => ['required', 'string'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $user = User::findByLogin($data['login']);
        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'login' => 'Email/nomor ponsel atau kata sandi salah.',
            ]);
        }
        if (! $user->is_active) {
            throw ValidationException::withMessages(['login' => 'Akun Anda dinonaktifkan. Hubungi admin Sirkula.']);
        }

        return $this->issueToken($user, $data['device_name'] ?? 'app');
    }

    /** Daftar akun customer (FR-A4). Mitra dan admin dibuat oleh admin. */
    public function register(Request $request, Notifier $notifier): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email', 'max:150', 'not_regex:/@sirkula\.id$/i'],
            'phone' => ['required', 'string', 'max:20'],
            'address' => ['required', 'string', 'max:255'],
            'password' => ['required', 'string', Password::min(8)->letters()->numbers()],
            'device_name' => ['nullable', 'string', 'max:100'],
        ], [
            'email.not_regex' => 'Email @sirkula.id khusus staf perusahaan.',
        ]);

        $email = mb_strtolower(trim($data['email']));
        $phone = User::normalizePhone($data['phone']);
        if (strlen($phone) < 9 || strlen($phone) > 15) {
            throw ValidationException::withMessages(['phone' => 'Nomor ponsel tidak valid.']);
        }
        if (User::where('email', $email)->exists()) {
            throw ValidationException::withMessages(['email' => 'Email sudah terdaftar. Silakan masuk.']);
        }
        if (User::where('phone', $phone)->exists()) {
            throw ValidationException::withMessages(['phone' => 'Nomor ponsel sudah terdaftar. Silakan masuk.']);
        }

        $user = DB::transaction(fn () => User::create([
            'code' => User::nextCode(Role::Customer),
            'role' => Role::Customer,
            'name' => trim($data['name']),
            'email' => $email,
            'phone' => $phone,
            'address' => trim($data['address']),
            'password' => $data['password'],
        ]));
        $notifier->send($user, 'Selamat datang di Sirkula', 'Setor sampah pertama Anda ke BSI Ias Toba untuk mendapat poin.');

        return $this->issueToken($user, $data['device_name'] ?? 'app', 201);
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user()->load('partner'));
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Berhasil keluar.']);
    }

    /**
     * Kirim kode verifikasi (FR-A5). Pengiriman lewat email/SMS belum ada,
     * jadi selama APP_DEBUG=true kodenya ikut dikembalikan di respons.
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        $data = $request->validate(['login' => ['required', 'string']]);
        $user = User::findByLogin($data['login']);
        $response = ['message' => 'Jika akun terdaftar, kode verifikasi sudah dikirim.'];

        if ($user && $user->is_active) {
            $code = (string) random_int(100000, 999999);
            DB::table('password_reset_tokens')->updateOrInsert(
                ['email' => $user->email],
                ['token' => Hash::make($code), 'created_at' => now()],
            );
            if (config('app.debug')) {
                $response['debug_code'] = $code;
            }
        }

        return response()->json($response);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'login' => ['required', 'string'],
            'code' => ['required', 'digits:6'],
            'password' => ['required', 'string', Password::min(8)->letters()->numbers()],
        ]);

        $user = User::findByLogin($data['login']);
        $row = $user ? DB::table('password_reset_tokens')->where('email', $user->email)->first() : null;
        $valid = $row
            && now()->diffInMinutes($row->created_at, true) <= self::RESET_TTL_MINUTES
            && Hash::check($data['code'], $row->token);
        if (! $valid) {
            throw ValidationException::withMessages(['code' => 'Kode verifikasi salah atau sudah kedaluwarsa.']);
        }

        $user->update(['password' => $data['password']]);
        $user->tokens()->delete();
        DB::table('password_reset_tokens')->where('email', $user->email)->delete();

        return response()->json(['message' => 'Kata sandi berhasil diganti. Silakan masuk.']);
    }

    private function issueToken(User $user, string $device, int $status = 200): JsonResponse
    {
        $token = $user->createToken($device)->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => new UserResource($user->load('partner')),
        ], $status);
    }
}
