<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\RedemptionStatus;
use App\Enums\Role;
use App\Http\Controllers\Controller;
use App\Models\Deposit;
use App\Models\Partner;
use App\Models\Redemption;
use App\Models\User;
use App\Support\Stats;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /** Beranda admin (FR-P1). */
    public function summary(Request $request): JsonResponse
    {
        $partner = Partner::main();
        $verified = Stats::verified()->where('partner_id', $partner->id);
        $month = Stats::totals($verified, now()->startOfMonth());

        $byGroup = Deposit::query()
            ->where('deposits.status', 'verified')
            ->where('deposits.weighed_at', '>=', now()->startOfMonth())
            ->join('waste_types', 'waste_types.id', '=', 'deposits.waste_type_id')
            ->join('waste_groups', 'waste_groups.id', '=', 'waste_types.waste_group_id')
            ->groupBy('waste_groups.code', 'waste_groups.name')
            ->selectRaw('waste_groups.code as code, waste_groups.name as name, SUM(deposits.weighed_kg) as kg')
            ->get()
            ->map(fn ($r) => ['code' => $r->code, 'name' => $r->name, 'kg' => round((float) $r->kg, 1)]);

        return response()->json([
            'partner' => ['id' => $partner->id, 'name' => $partner->name, 'monthly_target_kg' => $partner->monthly_target_kg],
            'kg_this_month' => $month['kg'],
            'target_progress' => $partner->monthly_target_kg > 0 ? min(1, $month['kg'] / $partner->monthly_target_kg) : 0,
            'co2_this_month_kg' => $month['co2_kg'],
            'points_this_month' => $month['points'],
            'active_customers_this_month' => $month['customers'],
            'total_customers' => User::ofRole(Role::Customer)->count(),
            'pending_redemptions' => Redemption::where('status', RedemptionStatus::Processing->value)->count(),
            'monthly_kg' => Stats::monthlyKg($verified),
            'kg_by_group_this_month' => $byGroup,
            'unread_notifications' => $request->user()->appNotifications()->whereNull('read_at')->count(),
        ]);
    }
}
