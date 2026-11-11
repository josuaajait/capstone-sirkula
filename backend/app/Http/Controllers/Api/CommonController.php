<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Http\Resources\PartnerResource;
use App\Http\Resources\RewardResource;
use App\Http\Resources\WasteTypeResource;
use App\Models\Partner;
use App\Models\Reward;
use App\Models\WasteGroup;
use App\Services\DepositService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/** Data yang dipakai semua peran. */
class CommonController extends Controller
{
    /** Bank sampah, slot jemput, dan batas berat. */
    public function config(): JsonResponse
    {
        return response()->json([
            'bank_sampah' => new PartnerResource(Partner::main()),
            'pickup_slots' => DepositService::PICKUP_SLOTS,
            'max_weigh_kg' => DepositService::MAX_KG,
            'reject_reasons' => [
                'Sampah kotor atau basah',
                'Sampah tercampur, belum dipilah',
                'Alamat di luar jangkauan jemput',
                'Jadwal jemput penuh',
            ],
        ]);
    }

    /** Kelompok dan jenis sampah aktif beserta poin per kg. */
    public function wasteTypes(): JsonResponse
    {
        $groups = WasteGroup::orderBy('sort')
            ->with(['types' => fn ($q) => $q->where('is_active', true)])
            ->get();

        return response()->json(['data' => $groups->map(fn (WasteGroup $g) => [
            'code' => $g->code,
            'name' => $g->name,
            'types' => WasteTypeResource::collection($g->types->each->setRelation('group', $g)),
        ])]);
    }

    /** Katalog hadiah aktif (FR-C7). */
    public function rewards(): AnonymousResourceCollection
    {
        return RewardResource::collection(
            Reward::where('is_active', true)->orderBy('points')->get()
        );
    }

    public function notifications(Request $request): AnonymousResourceCollection
    {
        $items = $request->user()->appNotifications()->latest()->latest('id')->paginate(30);

        return NotificationResource::collection($items)->additional([
            'unread' => $request->user()->appNotifications()->whereNull('read_at')->count(),
        ]);
    }

    public function readNotifications(Request $request): JsonResponse
    {
        $request->user()->appNotifications()->whereNull('read_at')->update(['read_at' => now()]);

        return response()->json(['message' => 'Semua notifikasi ditandai sudah dibaca.']);
    }
}
