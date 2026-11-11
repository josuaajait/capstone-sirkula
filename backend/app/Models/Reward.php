<?php

namespace App\Models;

use App\Enums\RewardCategory;
use Illuminate\Database\Eloquent\Model;

class Reward extends Model
{
    protected $fillable = [
        'code', 'initials', 'name', 'category', 'points', 'stock', 'description', 'is_active',
    ];

    protected function casts(): array
    {
        return [
            'category' => RewardCategory::class,
            'points' => 'integer',
            'stock' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    /** Kode berikutnya, misalnya RW-0005. */
    public static function nextCode(): string
    {
        $n = (int) static::max('id') + 1;

        do {
            $code = 'RW-'.str_pad((string) $n++, 4, '0', STR_PAD_LEFT);
        } while (static::where('code', $code)->exists());

        return $code;
    }
}
