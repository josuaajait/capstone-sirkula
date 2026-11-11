<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

/**
 * Menyajikan foto timbangan dari storage tanpa perlu `php artisan
 * storage:link` (symlink sering gagal di Windows). Nama file berisi 40
 * karakter acak, jadi tautannya tidak bisa ditebak.
 */
class MediaController extends Controller
{
    public function weighPhoto(string $file): BinaryFileResponse
    {
        $path = 'weigh-photos/'.$file;
        abort_unless(Storage::disk('public')->exists($path), 404);

        return response()->file(Storage::disk('public')->path($path), [
            'Cache-Control' => 'private, max-age=86400',
        ]);
    }
}
