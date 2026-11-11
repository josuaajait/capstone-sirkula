<?php

namespace App\Support;

use App\Enums\DepositStatus;
use App\Models\Deposit;
use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;

/** Perhitungan ringkasan yang dipakai beranda customer, mitra, dan admin. */
class Stats
{
    public static function verified(): Builder
    {
        return Deposit::where('status', DepositStatus::Verified->value);
    }

    /** Berat, poin, emisi, dan jumlah customer dari setoran terverifikasi pada rentang waktu. */
    public static function totals(Builder $verified, ?CarbonInterface $from = null, ?CarbonInterface $to = null): array
    {
        $query = (clone $verified)->with('wasteType');
        if ($from) {
            $query->where('weighed_at', '>=', $from);
        }
        if ($to) {
            $query->where('weighed_at', '<=', $to);
        }
        $rows = $query->get();

        return [
            'kg' => round($rows->sum('weighed_kg'), 1),
            'points' => (int) $rows->sum('points_earned'),
            'co2_kg' => round($rows->sum(fn (Deposit $d) => $d->weighed_kg * $d->wasteType->co2_per_kg), 1),
            'deposits' => $rows->count(),
            'customers' => $rows->pluck('customer_id')->unique()->count(),
        ];
    }

    /** Berat per bulan, $months bulan terakhir dari yang terlama (grafik FR-C1, FR-P1). */
    public static function monthlyKg(Builder $verified, int $months = 6): array
    {
        $start = Carbon::now()->startOfMonth()->subMonths($months - 1);
        $rows = (clone $verified)->where('weighed_at', '>=', $start)->get(['weighed_kg', 'weighed_at']);

        $result = [];
        for ($i = 0; $i < $months; $i++) {
            $month = $start->copy()->addMonths($i);
            $result[] = [
                'month' => $month->format('Y-m'),
                'kg' => round($rows->filter(fn ($d) => $d->weighed_at->isSameMonth($month))->sum('weighed_kg'), 1),
            ];
        }

        return $result;
    }
}
