<?php

namespace App\Services;

use App\Enums\RedemptionStatus;
use App\Exceptions\BusinessRuleException;
use App\Models\Redemption;
use App\Models\Reward;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/** Penukaran poin (FR-C9) dan pemrosesannya oleh perusahaan (FR-P6). */
class RedemptionService
{
    public function __construct(
        private readonly PointLedger $ledger,
        private readonly Notifier $notifier,
    ) {}

    public function redeem(User $customer, Reward $reward, string $address): Redemption
    {
        $redemption = DB::transaction(function () use ($customer, $reward, $address) {
            $reward = Reward::whereKey($reward->id)->lockForUpdate()->firstOrFail();
            if (! $reward->is_active) {
                throw new BusinessRuleException('Hadiah ini sudah tidak tersedia.', 'reward_inactive');
            }
            if ($reward->stock < 1) {
                throw new BusinessRuleException('Stok hadiah habis.', 'out_of_stock');
            }
            if ($customer->fresh()->points_balance < $reward->points) {
                throw new BusinessRuleException('Poin tidak cukup.', 'insufficient_points');
            }

            $redemption = Redemption::create([
                'code' => CodeGenerator::daily('RDM', Redemption::class, now()),
                'customer_id' => $customer->id,
                'reward_id' => $reward->id,
                'points' => $reward->points,
                'address' => trim($address),
                'status' => RedemptionStatus::Processing,
            ]);
            $reward->decrement('stock');
            $this->ledger->debit($customer, $reward->points, $redemption, "Tukar {$reward->name}");

            return $redemption;
        });

        $this->notifier->send($customer, 'Penukaran diproses', "{$reward->name} akan dikirim dalam 1–2 hari kerja.");
        $this->notifier->toAdmins('Penukaran baru', "{$customer->name} menukar {$reward->name} ({$redemption->code}).");

        return $redemption->load('reward');
    }

    /** Hadiah dikirim, dengan nomor resi atau kode digital. */
    public function ship(Redemption $redemption, string $trackingNumber, User $by): Redemption
    {
        if ($redemption->status !== RedemptionStatus::Processing) {
            throw new BusinessRuleException('Penukaran ini sudah dikirim.', 'invalid_status', 409);
        }
        $redemption->update([
            'status' => RedemptionStatus::Shipped,
            'tracking_number' => trim($trackingNumber),
            'shipped_at' => now(),
        ]);
        Audit::log($by, 'redemption.shipped', $redemption, ['tracking_number' => [null, $redemption->tracking_number]]);

        $this->notifier->send(
            $redemption->customer,
            'Hadiah dikirim',
            "{$redemption->reward->name} sudah dikirim. Nomor resi: {$redemption->tracking_number}.",
        );

        return $redemption;
    }

    public function complete(Redemption $redemption, User $by): Redemption
    {
        if ($redemption->status !== RedemptionStatus::Shipped) {
            throw new BusinessRuleException('Tandai dikirim dulu sebelum selesai.', 'invalid_status', 409);
        }
        $redemption->update(['status' => RedemptionStatus::Done, 'done_at' => now()]);
        Audit::log($by, 'redemption.done', $redemption);

        $this->notifier->send(
            $redemption->customer,
            'Penukaran selesai',
            "{$redemption->reward->name} sudah diterima. Terima kasih sudah memilah sampah.",
        );

        return $redemption;
    }
}
