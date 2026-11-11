<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use App\Services\FcmSender;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Mendaftarkan HP untuk notifikasi push (FCM). */
class DeviceController extends Controller
{
    public function store(Request $request, FcmSender $fcm): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['nullable', 'string', 'in:android,ios,web'],
        ]);

        // Satu token hanya milik akun yang terakhir masuk di HP itu.
        DeviceToken::updateOrCreate(
            ['token' => $data['token']],
            ['user_id' => $request->user()->id, 'platform' => $data['platform'] ?? null, 'last_seen_at' => now()],
        );

        return response()->json(['message' => 'Perangkat terdaftar.', 'push_enabled' => $fcm->enabled()]);
    }

    /** Dipanggil saat keluar akun agar HP tidak menerima notifikasi akun lama. */
    public function destroy(Request $request): JsonResponse
    {
        $data = $request->validate(['token' => ['required', 'string', 'max:512']]);
        DeviceToken::where('token', $data['token'])->where('user_id', $request->user()->id)->delete();

        return response()->json(['message' => 'Perangkat dihapus.']);
    }
}
