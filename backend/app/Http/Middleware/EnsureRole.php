<?php

namespace App\Http\Middleware;

use App\Enums\Role;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Peran diperiksa di server untuk setiap permintaan (kebutuhan keamanan PRD).
 * Pemakaian: ->middleware('role:customer') atau 'role:partner,admin'.
 */
class EnsureRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();
        if (! $user || ! $user->is_active) {
            return response()->json(['message' => 'Akun tidak aktif.', 'reason' => 'inactive'], 403);
        }
        $allowed = array_map(fn (string $r) => Role::from($r), $roles);
        if (! in_array($user->role, $allowed, true)) {
            return response()->json(['message' => 'Akun Anda tidak punya akses ke fitur ini.', 'reason' => 'forbidden_role'], 403);
        }

        return $next($request);
    }
}
