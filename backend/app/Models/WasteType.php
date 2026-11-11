<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WasteType extends Model
{
    protected $fillable = [
        'waste_group_id', 'code', 'name', 'examples', 'points_per_kg',
        'co2_per_kg', 'is_active', 'sort',
    ];

    protected function casts(): array
    {
        return [
            'points_per_kg' => 'integer',
            'co2_per_kg' => 'float',
            'is_active' => 'boolean',
        ];
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(WasteGroup::class, 'waste_group_id');
    }

    /** Berat dicatat sampai 0,1 kg (aturan PRD). */
    public static function roundKg(float $kg): float
    {
        return round($kg, 1);
    }

    /** Poin dibulatkan ke bawah (aturan PRD). */
    public static function pointsFor(float $kg, int $pointsPerKg): int
    {
        // Hitung dalam persepuluhan kg agar tidak terkena galat pecahan biner
        // (8,4 kg × 500 harus tepat 4.200, bukan 4.199).
        return intdiv((int) round($kg * 10) * $pointsPerKg, 10);
    }
}
