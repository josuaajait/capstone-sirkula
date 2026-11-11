<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/** Bank sampah mitra. Rilis pertama hanya BSI Ias Toba. */
class Partner extends Model
{
    protected $fillable = [
        'code', 'name', 'initials', 'address', 'area', 'hours', 'phone',
        'monthly_target_kg', 'is_active',
    ];

    protected function casts(): array
    {
        return ['monthly_target_kg' => 'float', 'is_active' => 'boolean'];
    }

    /** Satu-satunya bank sampah yang dilayani. */
    public static function main(): self
    {
        return static::where('is_active', true)->orderBy('id')->firstOrFail();
    }

    public function vehicles(): HasMany
    {
        return $this->hasMany(Vehicle::class);
    }

    public function staff(): HasMany
    {
        return $this->hasMany(User::class);
    }

    public function deposits(): HasMany
    {
        return $this->hasMany(Deposit::class);
    }
}
