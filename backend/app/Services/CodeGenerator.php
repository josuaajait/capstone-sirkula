<?php

namespace App\Services;

use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Model;

/**
 * Membuat kode harian seperti STR-261111-01 (setoran) dan RDM-261111-01
 * (penukaran). Dipanggil di dalam transaksi; kolom kode juga unik di basis data.
 */
class CodeGenerator
{
    /** @param class-string<Model> $model */
    public static function daily(string $prefix, string $model, CarbonInterface $at): string
    {
        $base = $prefix.'-'.$at->format('ymd').'-';
        $last = $model::where('code', 'like', $base.'%')
            ->lockForUpdate()
            ->orderByDesc('code')
            ->value('code');
        $n = $last ? ((int) substr($last, strlen($base))) + 1 : 1;

        return $base.str_pad((string) $n, 2, '0', STR_PAD_LEFT);
    }
}
