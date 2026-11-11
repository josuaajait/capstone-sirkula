<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Http\Resources\RedemptionResource;
use App\Models\Reward;
use App\Services\RedemptionService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/** Penukaran poin (FR-C8 sampai FR-C10). */
class RedemptionController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        return RedemptionResource::collection(
            $request->user()->redemptions()->with('reward')->latest()->latest('id')->paginate(30)
        );
    }

    public function store(Request $request, RedemptionService $service): RedemptionResource
    {
        $data = $request->validate([
            'reward_id' => ['required', 'integer', 'exists:rewards,id'],
            'address' => ['required', 'string', 'max:255'],
        ]);

        return new RedemptionResource(
            $service->redeem($request->user(), Reward::findOrFail($data['reward_id']), $data['address'])
        );
    }
}
