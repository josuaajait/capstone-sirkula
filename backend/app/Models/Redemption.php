<?php

namespace App\Models;

use App\Enums\RedemptionStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Redemption extends Model
{
    protected $fillable = [
        'code', 'customer_id', 'reward_id', 'points', 'address', 'status',
        'tracking_number', 'shipped_at', 'done_at', 'created_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => RedemptionStatus::class,
            'points' => 'integer',
            'shipped_at' => 'datetime',
            'done_at' => 'datetime',
        ];
    }

    public function getRouteKeyName(): string
    {
        return 'code';
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function reward(): BelongsTo
    {
        return $this->belongsTo(Reward::class);
    }
}
