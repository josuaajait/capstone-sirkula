<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/** Kelompok sampah: Plastik, Kertas, Kaleng, Kaca. */
class WasteGroup extends Model
{
    protected $fillable = ['code', 'name', 'sort'];

    public function types(): HasMany
    {
        return $this->hasMany(WasteType::class)->orderBy('sort');
    }
}
