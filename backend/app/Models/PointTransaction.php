<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use LogicException;

/** Catatan perubahan saldo. Tidak bisa diubah atau dihapus setelah dibuat. */
class PointTransaction extends Model
{
    public const UPDATED_AT = null;

    protected $fillable = [
        'user_id', 'amount', 'balance_after', 'source_type', 'source_id',
        'description', 'created_by', 'created_at',
    ];

    protected function casts(): array
    {
        return ['amount' => 'integer', 'balance_after' => 'integer'];
    }

    protected static function booted(): void
    {
        static::updating(fn () => throw new LogicException('Transaksi poin tidak bisa diubah.'));
        static::deleting(fn () => throw new LogicException('Transaksi poin tidak bisa dihapus.'));
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function source(): MorphTo
    {
        return $this->morphTo();
    }
}
