<?php

namespace App\Services;

use App\Exceptions\BusinessRuleException;
use App\Models\PointTransaction;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

/**
 * Satu-satunya jalan untuk mengubah saldo poin. Setiap perubahan menyimpan
 * catatan yang tidak bisa diubah, dan saldo tidak boleh negatif (aturan PRD).
 */
class PointLedger
{
    public function credit(User $user, int $amount, ?Model $source, string $description, ?User $by = null): PointTransaction
    {
        return $this->apply($user, abs($amount), $source, $description, $by);
    }

    public function debit(User $user, int $amount, ?Model $source, string $description, ?User $by = null): PointTransaction
    {
        return $this->apply($user, -abs($amount), $source, $description, $by);
    }

    private function apply(User $user, int $amount, ?Model $source, string $description, ?User $by): PointTransaction
    {
        return DB::transaction(function () use ($user, $amount, $source, $description, $by) {
            $locked = User::whereKey($user->getKey())->lockForUpdate()->firstOrFail();
            $balance = $locked->points_balance + $amount;
            if ($balance < 0) {
                throw new BusinessRuleException('Poin tidak cukup.', 'insufficient_points');
            }
            $locked->points_balance = $balance;
            $locked->save();
            $user->points_balance = $balance;

            return PointTransaction::create([
                'user_id' => $locked->id,
                'amount' => $amount,
                'balance_after' => $balance,
                'source_type' => $source?->getMorphClass(),
                'source_id' => $source?->getKey(),
                'description' => $description,
                'created_by' => $by?->id,
            ]);
        });
    }
}
