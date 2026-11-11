<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class Audit
{
    /** Catat perubahan model. $changes berisi ['kolom' => [lama, baru]]. */
    public static function log(?User $by, string $action, ?Model $subject, array $changes = []): void
    {
        AuditLog::create([
            'user_id' => $by?->id,
            'action' => $action,
            'subject_type' => $subject?->getMorphClass(),
            'subject_id' => $subject?->getKey(),
            'changes' => $changes ?: null,
        ]);
    }

    /** Ambil perubahan dari model yang sudah di-fill tetapi belum disimpan. */
    public static function diff(Model $model): array
    {
        $changes = [];
        foreach ($model->getDirty() as $key => $new) {
            $changes[$key] = [$model->getOriginal($key), $new];
        }

        return $changes;
    }
}
