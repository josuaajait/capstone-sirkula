<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\DepositStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\DepositResource;
use App\Models\Deposit;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/** Pantau setoran di BSI Ias Toba, dengan pencarian dan filter (FR-P3). */
class DepositController extends Controller
{
    private const RELATIONS = ['partner', 'wasteType.group', 'vehicle', 'customer'];

    public function index(Request $request): AnonymousResourceCollection
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', Rule::enum(DepositStatus::class)],
            'waste_type_id' => ['nullable', 'integer'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);

        return DepositResource::collection(
            self::filtered($filters)->with(self::RELATIONS)->latest()->latest('id')->paginate(50)
        );
    }

    public function show(Deposit $deposit): DepositResource
    {
        return new DepositResource($deposit->load(self::RELATIONS));
    }

    /** Dipakai juga oleh laporan. Tanggal memakai waktu permintaan dibuat. */
    public static function filtered(array $filters): Builder
    {
        return Deposit::query()
            ->when($filters['search'] ?? null, function (Builder $q, string $s) {
                $digits = User::normalizePhone($s);
                $q->where(function (Builder $q) use ($s, $digits) {
                    $q->where('code', 'like', "%{$s}%")
                        ->orWhereHas('customer', fn (Builder $c) => $c
                            ->where('name', 'like', "%{$s}%")
                            ->orWhere('code', 'like', "%{$s}%")
                            ->when(strlen($digits) >= 4, fn ($c) => $c->orWhere('phone', 'like', "%{$digits}%")));
                });
            })
            ->when($filters['status'] ?? null, fn (Builder $q, $s) => $q->where('status', $s))
            ->when($filters['waste_type_id'] ?? null, fn (Builder $q, $t) => $q->where('waste_type_id', $t))
            ->when($filters['from'] ?? null, fn (Builder $q, $d) => $q->whereDate('created_at', '>=', $d))
            ->when($filters['to'] ?? null, fn (Builder $q, $d) => $q->whereDate('created_at', '<=', $d));
    }
}
