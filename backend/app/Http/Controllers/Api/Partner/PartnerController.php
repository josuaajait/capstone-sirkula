<?php

namespace App\Http\Controllers\Api\Partner;

use App\Enums\DepositMethod;
use App\Enums\DepositStatus;
use App\Enums\Role;
use App\Http\Controllers\Controller;
use App\Http\Resources\DepositResource;
use App\Http\Resources\VehicleResource;
use App\Models\Partner;
use App\Models\User;
use App\Models\Vehicle;
use App\Support\Stats;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class PartnerController extends Controller
{
    /** Beranda mitra (FR-M1). */
    public function summary(Request $request): JsonResponse
    {
        $partner = $this->partner($request);
        $verified = Stats::verified()->where('partner_id', $partner->id);
        $month = Stats::totals($verified, now()->startOfMonth());

        $todayPickups = $partner->deposits()
            ->where('method', DepositMethod::Pickup->value)
            ->whereIn('status', [DepositStatus::Scheduled->value, DepositStatus::OnTheWay->value])
            ->whereDate('pickup_date', today())
            ->with(['partner', 'wasteType.group', 'vehicle', 'customer'])
            ->orderBy('pickup_slot')
            ->get();

        return response()->json([
            'partner' => ['id' => $partner->id, 'name' => $partner->name, 'monthly_target_kg' => $partner->monthly_target_kg],
            'kg_this_month' => $month['kg'],
            'target_progress' => $partner->monthly_target_kg > 0 ? min(1, $month['kg'] / $partner->monthly_target_kg) : 0,
            'points_this_month' => $month['points'],
            'customers_this_month' => $month['customers'],
            'pending_requests' => $partner->deposits()->where('status', DepositStatus::Waiting->value)->count(),
            'today_pickups' => DepositResource::collection($todayPickups),
            'unread_notifications' => $request->user()->appNotifications()->whereNull('read_at')->count(),
        ]);
    }

    /** Cari customer lewat nomor ponsel atau ID (FR-M4). */
    public function findCustomer(Request $request): JsonResponse
    {
        $q = trim((string) $request->validate(['q' => ['required', 'string', 'max:30']])['q']);
        $query = User::ofRole(Role::Customer)->where('is_active', true);

        $customer = (clone $query)->where('code', mb_strtoupper($q))->first();
        if (! $customer) {
            $digits = User::normalizePhone($q);
            if (strlen($digits) >= 6) {
                $customer = (clone $query)->where('phone', $digits)->first()
                    ?? (clone $query)->where('phone', 'like', '%'.ltrim($digits, '0'))->first();
            }
        }
        if (! $customer) {
            return response()->json(['message' => 'Customer tidak ditemukan.'], 404);
        }

        return response()->json(['data' => [
            'id' => $customer->id,
            'code' => $customer->code,
            'name' => $customer->name,
            'initials' => $customer->initials(),
            'phone' => $customer->phone,
            'address' => $customer->address,
            'points_balance' => $customer->points_balance,
            // Setoran yang sudah diterima dan menunggu ditimbang.
            'ready_to_weigh' => DepositResource::collection(
                $customer->deposits()
                    ->where('partner_id', $this->partner($request)->id)
                    ->whereIn('status', [DepositStatus::Scheduled->value, DepositStatus::OnTheWay->value])
                    ->with(['partner', 'wasteType.group', 'vehicle', 'customer'])
                    ->get()
            ),
        ]]);
    }

    public function vehicles(Request $request): AnonymousResourceCollection
    {
        return VehicleResource::collection(
            $this->partner($request)->vehicles()->where('is_active', true)->orderBy('id')->get()
        );
    }

    public function storeVehicle(Request $request): VehicleResource
    {
        $data = $request->validate([
            'type' => ['required', 'string', 'max:50'],
            'plate' => ['required', 'string', 'max:20'],
        ]);

        return new VehicleResource($this->partner($request)->vehicles()->create([
            'type' => trim($data['type']),
            'plate' => mb_strtoupper(trim($data['plate'])),
        ]));
    }

    public function deleteVehicle(Request $request, Vehicle $vehicle): JsonResponse
    {
        abort_unless($vehicle->partner_id === $this->partner($request)->id, 404);
        $vehicle->update(['is_active' => false]);

        return response()->json(['message' => 'Kendaraan dihapus dari daftar.']);
    }

    public static function partner(Request $request): Partner
    {
        $partner = $request->user()->partner;
        abort_unless($partner, 403, 'Akun mitra belum terhubung ke bank sampah.');

        return $partner;
    }
}
