<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Notifikasi di dalam aplikasi (PRD: semua kabar hanya lewat aplikasi). */
class AppNotification extends Model
{
    protected $fillable = ['user_id', 'title', 'body', 'read_at', 'created_at'];

    protected function casts(): array
    {
        return ['read_at' => 'datetime'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
