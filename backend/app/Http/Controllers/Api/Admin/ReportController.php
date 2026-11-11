<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\RedemptionStatus;
use App\Http\Controllers\Controller;
use App\Models\Deposit;
use App\Models\Redemption;
use App\Support\Stats;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Laporan berat, tCO2e, customer aktif, poin, dan penukaran (FR-P7).
 * Unduhan Excel memakai CSV yang langsung terbuka di Excel; PDF menyusul.
 */
class ReportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        [$from, $to] = $this->range($request);

        return response()->json($this->build($from, $to));
    }

    public function exportCsv(Request $request): StreamedResponse
    {
        [$from, $to] = $this->range($request);
        $report = $this->build($from, $to);
        $deposits = Stats::verified()
            ->whereBetween('weighed_at', [$from, $to])
            ->with(['customer', 'wasteType'])
            ->orderBy('weighed_at')
            ->get();
        $filename = 'laporan-sirkula-'.$from->format('Ymd').'-'.$to->format('Ymd').'.csv';

        return response()->streamDownload(function () use ($report, $deposits) {
            $out = fopen('php://output', 'w');
            fwrite($out, "\xEF\xBB\xBF"); // BOM agar Excel membaca UTF-8
            $row = fn (array $cells) => fputcsv($out, $cells, ';');
            $num = fn (float $n) => str_replace('.', ',', (string) $n);

            $row(['Laporan Sirkula', $report['period']['from'].' s.d. '.$report['period']['to']]);
            $row([]);
            $row(['Ringkasan']);
            $row(['Total berat (kg)', $num($report['totals']['kg'])]);
            $row(['Emisi terhindarkan (tCO2e)', $num($report['totals']['tco2e'])]);
            $row(['Jumlah setoran', $report['totals']['deposits']]);
            $row(['Customer aktif', $report['totals']['active_customers']]);
            $row(['Poin diberikan', $report['totals']['points_given']]);
            $row(['Hadiah ditukar', $report['redemptions']['count']]);
            $row(['Poin dipakai untuk hadiah', $report['redemptions']['points']]);
            $row([]);
            $row(['Per jenis sampah']);
            $row(['Kelompok', 'Jenis', 'Berat (kg)', 'Poin']);
            foreach ($report['by_type'] as $t) {
                $row([$t['group'], $t['name'], $num($t['kg']), $t['points']]);
            }
            $row([]);
            $row(['Rincian setoran']);
            $row(['Kode', 'Tanggal timbang', 'Customer', 'ID customer', 'Jenis', 'Berat (kg)', 'Poin']);
            foreach ($deposits as $d) {
                $row([$d->code, $d->weighed_at->format('Y-m-d H:i'), $d->customer->name, $d->customer->code,
                    $d->wasteType->name, $num($d->weighed_kg), $d->points_earned]);
            }
            fclose($out);
        }, $filename, ['Content-Type' => 'text/csv; charset=UTF-8']);
    }

    private function build(Carbon $from, Carbon $to): array
    {
        $totals = Stats::totals(Stats::verified(), $from, $to);
        $byType = Deposit::query()
            ->where('deposits.status', 'verified')
            ->whereBetween('deposits.weighed_at', [$from, $to])
            ->join('waste_types', 'waste_types.id', '=', 'deposits.waste_type_id')
            ->join('waste_groups', 'waste_groups.id', '=', 'waste_types.waste_group_id')
            ->groupBy('waste_groups.name', 'waste_types.name', 'waste_groups.sort', 'waste_types.sort')
            ->orderBy('waste_groups.sort')->orderBy('waste_types.sort')
            ->selectRaw('waste_groups.name as grp, waste_types.name as name, SUM(deposits.weighed_kg) as kg, SUM(deposits.points_earned) as points')
            ->get()
            ->map(fn ($r) => ['group' => $r->grp, 'name' => $r->name, 'kg' => round((float) $r->kg, 1), 'points' => (int) $r->points]);
        $redemptions = Redemption::whereBetween('created_at', [$from, $to]);

        return [
            'period' => ['from' => $from->toDateString(), 'to' => $to->toDateString()],
            'totals' => [
                'kg' => $totals['kg'],
                'tco2e' => round($totals['co2_kg'] / 1000, 3),
                'deposits' => $totals['deposits'],
                'active_customers' => $totals['customers'],
                'points_given' => $totals['points'],
            ],
            'by_type' => $byType,
            'redemptions' => [
                'count' => (clone $redemptions)->count(),
                'points' => (int) (clone $redemptions)->sum('points'),
                'pending' => (clone $redemptions)->where('status', RedemptionStatus::Processing->value)->count(),
            ],
        ];
    }

    /** Default: bulan berjalan. */
    private function range(Request $request): array
    {
        $data = $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);
        $from = isset($data['from']) ? Carbon::parse($data['from'])->startOfDay() : now()->startOfMonth();
        $to = isset($data['to']) ? Carbon::parse($data['to'])->endOfDay() : now()->endOfDay();

        return [$from, $to];
    }
}
