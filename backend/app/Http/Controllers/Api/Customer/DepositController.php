<?php

namespace App\Http\Controllers\Api\Customer;

use App\Enums\DepositMethod;
use App\Enums\DepositStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\DepositResource;
use App\Models\Deposit;
use App\Services\DepositService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/** Setoran milik customer yang sedang masuk (FR-C3 sampai FR-C6). */
class DepositController extends Controller
{
    private const RELATIONS = ['partner', 'wasteType.group', 'vehicle', 'customer'];

    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['status' => ['nullable', Rule::enum(DepositStatus::class)]]);

        return DepositResource::collection(
            $request->user()->deposits()
                ->when($request->status, fn ($q, $s) => $q->where('status', $s))
                ->with(self::RELATIONS)
                ->latest()->latest('id')
                ->paginate(30)
        );
    }

    public function store(Request $request, DepositService $service): DepositResource
    {
        $data = $request->validate([
            'waste_type_id' => ['required', 'integer', Rule::exists('waste_types', 'id')->where('is_active', true)],
            'estimated_kg' => ['required', 'numeric', 'gt:0', 'max:'.DepositService::MAX_KG],
            'method' => ['required', Rule::enum(DepositMethod::class)],
            'pickup_date' => ['required_if:method,pickup', 'nullable', 'date', 'after_or_equal:today'],
            'pickup_slot' => ['required_if:method,pickup', 'nullable', Rule::in(DepositService::PICKUP_SLOTS)],
            'address' => ['required_if:method,pickup', 'nullable', 'string', 'max:255'],
            'note' => ['nullable', 'string', 'max:500'],
        ]);

        $deposit = $service->create($request->user(), $data);

        return new DepositResource($deposit->load(self::RELATIONS));
    }

    public function show(Request $request, Deposit $deposit): DepositResource
    {
        abort_unless($deposit->customer_id === $request->user()->id, 404);

        return new DepositResource($deposit->load(self::RELATIONS));
    }
}
