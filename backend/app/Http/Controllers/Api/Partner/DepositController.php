<?php

namespace App\Http\Controllers\Api\Partner;

use App\Enums\DepositStatus;
use App\Enums\Role;
use App\Http\Controllers\Controller;
use App\Http\Resources\DepositResource;
use App\Models\Deposit;
use App\Models\User;
use App\Models\Vehicle;
use App\Models\WasteType;
use App\Services\DepositService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/** Permintaan, jadwal jemput, dan penimbangan di sisi mitra (FR-M2 sampai FR-M7). */
class DepositController extends Controller
{
    private const RELATIONS = ['partner', 'wasteType.group', 'vehicle', 'customer'];

    public function __construct(private readonly DepositService $service) {}

    /**
     * Daftar setoran. Filter `view`:
     * requests (menunggu), pickups (jemput terjadwal), ready (siap ditimbang),
     * history (sudah ditimbang), atau kosong untuk semua.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'view' => ['nullable', Rule::in(['requests', 'pickups', 'ready', 'history'])],
            'status' => ['nullable', Rule::enum(DepositStatus::class)],
        ]);
        $active = [DepositStatus::Scheduled->value, DepositStatus::OnTheWay->value];
        $query = PartnerController::partner($request)->deposits()->with(self::RELATIONS);

        match ($request->view) {
            'requests' => $query->where('status', DepositStatus::Waiting->value)->oldest()->oldest('id'),
            'pickups' => $query->where('method', 'pickup')->whereIn('status', $active)->orderBy('pickup_date')->orderBy('pickup_slot'),
            'ready' => $query->whereIn('status', $active)->orderByRaw('COALESCE(pickup_date, created_at)'),
            'history' => $query->where('status', DepositStatus::Verified->value)->latest('weighed_at')->latest('id'),
            default => $query->when($request->status, fn ($q, $s) => $q->where('status', $s))->latest()->latest('id'),
        };

        return DepositResource::collection($query->paginate(50));
    }

    public function show(Request $request, Deposit $deposit): DepositResource
    {
        $this->authorizeDeposit($request, $deposit);

        return new DepositResource($deposit->load(self::RELATIONS));
    }

    public function accept(Request $request, Deposit $deposit): DepositResource
    {
        $this->authorizeDeposit($request, $deposit);
        $data = $request->validate([
            'pickup_date' => ['nullable', 'date', 'after_or_equal:today'],
            'pickup_slot' => ['nullable', Rule::in(DepositService::PICKUP_SLOTS)],
            'vehicle_id' => ['nullable', 'integer'],
        ]);

        $this->service->accept(
            $deposit,
            $data['pickup_date'] ?? null,
            $data['pickup_slot'] ?? null,
            $this->vehicle($request, $data['vehicle_id'] ?? null),
        );

        return new DepositResource($deposit->refresh()->load(self::RELATIONS));
    }

    public function reject(Request $request, Deposit $deposit): DepositResource
    {
        $this->authorizeDeposit($request, $deposit);
        $data = $request->validate(['reason' => ['required', 'string', 'max:255']]);
        $this->service->reject($deposit, trim($data['reason']));

        return new DepositResource($deposit->refresh()->load(self::RELATIONS));
    }

    public function reschedule(Request $request, Deposit $deposit): DepositResource
    {
        $this->authorizeDeposit($request, $deposit);
        $data = $request->validate([
            'pickup_date' => ['required', 'date', 'after_or_equal:today'],
            'pickup_slot' => ['required', Rule::in(DepositService::PICKUP_SLOTS)],
            'vehicle_id' => ['required', 'integer'],
        ]);
        $this->service->reschedule($deposit, $data['pickup_date'], $data['pickup_slot'], $this->vehicle($request, $data['vehicle_id']));

        return new DepositResource($deposit->refresh()->load(self::RELATIONS));
    }

    public function depart(Request $request, Deposit $deposit): DepositResource
    {
        $this->authorizeDeposit($request, $deposit);
        $this->service->depart($deposit);

        return new DepositResource($deposit->refresh()->load(self::RELATIONS));
    }

    /** Catat timbangan untuk setoran yang sudah diterima (FR-M4, FR-M6). */
    public function weigh(Request $request, Deposit $deposit): DepositResource
    {
        $this->authorizeDeposit($request, $deposit);
        $data = $this->validateWeighing($request);

        $this->service->weigh(
            $deposit,
            $deposit->customer,
            WasteType::findOrFail($data['waste_type_id']),
            (float) $data['weighed_kg'],
            $data['note'] ?? null,
            $request->user(),
        );

        return new DepositResource($deposit->refresh()->load(self::RELATIONS));
    }

    /** Koreksi berat yang salah catat beserta alasannya (FR-M8). */
    public function correct(Request $request, Deposit $deposit): DepositResource
    {
        $this->authorizeDeposit($request, $deposit);
        $data = $request->validate([
            'weighed_kg' => ['required', 'numeric', 'gt:0', 'max:'.DepositService::MAX_KG],
            'reason' => ['required', 'string', 'min:5', 'max:255'],
            'points' => ['prohibited'],
        ], ['points.prohibited' => 'Poin dihitung otomatis oleh sistem.']);

        $this->service->correct($deposit, (float) $data['weighed_kg'], trim($data['reason']), $request->user());

        return new DepositResource($deposit->refresh()->load(self::RELATIONS));
    }

    /** Catat setoran customer yang datang langsung tanpa permintaan (FR-M5). */
    public function walkIn(Request $request): DepositResource
    {
        $data = $this->validateWeighing($request, withCustomer: true);
        $customer = User::ofRole(Role::Customer)->where('is_active', true)->findOrFail($data['customer_id']);

        $deposit = $this->service->weigh(
            null,
            $customer,
            WasteType::findOrFail($data['waste_type_id']),
            (float) $data['weighed_kg'],
            $data['note'] ?? null,
            $request->user(),
        );

        return new DepositResource($deposit->load(self::RELATIONS));
    }

    private function validateWeighing(Request $request, bool $withCustomer = false): array
    {
        return $request->validate([
            'customer_id' => $withCustomer ? ['required', 'integer'] : ['prohibited'],
            'waste_type_id' => ['required', 'integer', Rule::exists('waste_types', 'id')->where('is_active', true)],
            // Poin tidak bisa dikirim mitra; selalu dihitung server (FR-M6).
            'weighed_kg' => ['required', 'numeric', 'gt:0', 'max:'.DepositService::MAX_KG],
            'note' => ['nullable', 'string', 'max:500'],
            'points' => ['prohibited'],
        ], ['points.prohibited' => 'Poin dihitung otomatis oleh sistem.']);
    }

    private function vehicle(Request $request, ?int $id): ?Vehicle
    {
        if ($id === null) {
            return null;
        }

        return PartnerController::partner($request)->vehicles()->where('is_active', true)->findOrFail($id);
    }

    private function authorizeDeposit(Request $request, Deposit $deposit): void
    {
        abort_unless($deposit->partner_id === PartnerController::partner($request)->id, 404);
    }
}
