<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\RedemptionStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\RedemptionResource;
use App\Models\Redemption;
use App\Services\RedemptionService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/** Memproses penukaran: kirim hadiah, catat resi, tandai selesai (FR-P6). */
class RedemptionController extends Controller
{
    public function __construct(private readonly RedemptionService $service) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['status' => ['nullable', Rule::enum(RedemptionStatus::class)]]);

        return RedemptionResource::collection(
            Redemption::with(['reward', 'customer'])
                ->when($request->status, fn ($q, $s) => $q->where('status', $s))
                ->oldest()->oldest('id')
                ->paginate(50)
        );
    }

    public function ship(Request $request, Redemption $redemption): RedemptionResource
    {
        $data = $request->validate(['tracking_number' => ['required', 'string', 'max:100']]);
        $this->service->ship($redemption->load(['reward', 'customer']), $data['tracking_number'], $request->user());

        return new RedemptionResource($redemption);
    }

    public function complete(Request $request, Redemption $redemption): RedemptionResource
    {
        $this->service->complete($redemption->load(['reward', 'customer']), $request->user());

        return new RedemptionResource($redemption);
    }
}
