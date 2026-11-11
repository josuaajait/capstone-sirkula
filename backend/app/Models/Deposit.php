<?php

namespace App\Models;

use App\Enums\DepositMethod;
use App\Enums\DepositStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Deposit extends Model
{
    protected $fillable = [
        'code', 'customer_id', 'partner_id', 'waste_type_id', 'estimated_kg',
        'method', 'status', 'is_walk_in', 'pickup_date', 'pickup_slot', 'address',
        'note', 'vehicle_id', 'accepted_at', 'departed_at', 'weighed_kg',
        'points_per_kg', 'points_earned', 'weighed_at', 'weighed_by', 'weigh_note',
        'weigh_photo_path', 'original_weighed_kg', 'corrected_at', 'correction_reason', 'rejected_at', 'reject_reason', 'created_at',
    ];

    protected function casts(): array
    {
        return [
            'method' => DepositMethod::class,
            'status' => DepositStatus::class,
            'estimated_kg' => 'float',
            'weighed_kg' => 'float',
            'points_per_kg' => 'integer',
            'points_earned' => 'integer',
            'is_walk_in' => 'boolean',
            'pickup_date' => 'date',
            'accepted_at' => 'datetime',
            'departed_at' => 'datetime',
            'weighed_at' => 'datetime',
            'corrected_at' => 'datetime',
            'original_weighed_kg' => 'float',
            'rejected_at' => 'datetime',
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

    public function partner(): BelongsTo
    {
        return $this->belongsTo(Partner::class);
    }

    public function wasteType(): BelongsTo
    {
        return $this->belongsTo(WasteType::class);
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function weigher(): BelongsTo
    {
        return $this->belongsTo(User::class, 'weighed_by');
    }

    /** Estimasi poin dari berat perkiraan customer, memakai tarif saat ini. */
    public function estimatedPoints(): int
    {
        return WasteType::pointsFor($this->estimated_kg, $this->wasteType->points_per_kg);
    }
}
