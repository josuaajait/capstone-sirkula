<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Kendaraan milik mitra untuk menjemput (FR-M3). */
class Vehicle extends Model
{
    protected $fillable = ['partner_id', 'type', 'plate', 'is_active'];

    protected function casts(): array
    {
        return ['is_active' => 'boolean'];
    }

    public function partner(): BelongsTo
    {
        return $this->belongsTo(Partner::class);
    }

    public function label(): string
    {
        return "{$this->type} · {$this->plate}";
    }
}
