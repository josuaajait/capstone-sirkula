<?php

namespace App\Http\Controllers\Api\Customer;

use App\Enums\DepositMethod;
use App\Enums\DepositStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\DepositResource;
use App\Http\Resources\PointTransactionResource;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Support\Stats;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class CustomerController extends Controller
{
    /** Beranda customer (FR-C1). */
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        $verified = Stats::verified()->where('customer_id', $user->id);
        $all = Stats::totals($verified);
        $month = Stats::totals($verified, now()->startOfMonth());

        $activePickups = $user->deposits()
            ->where('method', DepositMethod::Pickup->value)
            ->whereIn('status', [DepositStatus::Waiting->value, DepositStatus::Scheduled->value, DepositStatus::OnTheWay->value])
            ->with(['partner', 'wasteType.group', 'vehicle', 'customer'])
            ->orderByRaw('COALESCE(pickup_date, created_at)')
            ->get();

        return response()->json([
            'points_balance' => $user->points_balance,
            'total_verified_kg' => $all['kg'],
            'co2_avoided_kg' => $all['co2_kg'],
            'points_this_month' => $month['points'],
            'monthly_kg' => Stats::monthlyKg($verified),
            'active_pickups' => DepositResource::collection($activePickups),
            'unread_notifications' => $user->appNotifications()->whereNull('read_at')->count(),
        ]);
    }

    /** Ubah data akun (FR-C11). */
    public function updateProfile(Request $request): UserResource
    {
        $user = $request->user();
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email', 'max:150', 'not_regex:/@sirkula\.id$/i', Rule::unique('users')->ignore($user->id)],
            'phone' => ['required', 'string', 'max:20'],
            'address' => ['required', 'string', 'max:255'],
        ], ['email.not_regex' => 'Email @sirkula.id khusus staf perusahaan.']);

        $phone = User::normalizePhone($data['phone']);
        if (User::where('phone', $phone)->whereKeyNot($user->id)->exists()) {
            throw ValidationException::withMessages(['phone' => 'Nomor ponsel sudah dipakai akun lain.']);
        }
        $user->update([
            'name' => trim($data['name']),
            'email' => mb_strtolower(trim($data['email'])),
            'phone' => $phone,
            'address' => trim($data['address']),
        ]);

        return new UserResource($user);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', Password::min(8)->letters()->numbers()],
        ]);
        $user = $request->user();
        if (! Hash::check($data['current_password'], $user->password)) {
            throw ValidationException::withMessages(['current_password' => 'Kata sandi lama salah.']);
        }
        $user->update(['password' => $data['password']]);

        return response()->json(['message' => 'Kata sandi berhasil diganti.']);
    }

    /** Riwayat perubahan saldo poin. */
    public function points(Request $request): AnonymousResourceCollection
    {
        return PointTransactionResource::collection(
            $request->user()->pointTransactions()->latest('id')->paginate(30)
        )->additional(['points_balance' => $request->user()->points_balance]);
    }
}
