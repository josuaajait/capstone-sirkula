<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;

/** Log perubahan penting: poin per kg, data bank sampah, status penukaran. */
class AuditLog extends Model
{
    public const UPDATED_AT = null;

    protected $fillable = ['user_id', 'action', 'subject_type', 'subject_id', 'changes'];

    protected function casts(): array
    {
        return ['changes' => 'array'];
    }

    public function subject(): MorphTo
    {
        return $this->morphTo();
    }
}
