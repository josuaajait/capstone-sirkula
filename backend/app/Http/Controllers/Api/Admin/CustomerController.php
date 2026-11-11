<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\Role;
use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/** Daftar customer beserta saldo poinnya. */
class CustomerController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $search = trim((string) $request->query('search', ''));
        $digits = User::normalizePhone($search);

        return UserResource::collection(
            User::ofRole(Role::Customer)
                ->when($search !== '', fn ($q) => $q->where(fn ($q) => $q
                    ->where('name', 'like', "%{$search}%")
                    ->orWhere('code', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->when(strlen($digits) >= 4, fn ($q) => $q->orWhere('phone', 'like', "%{$digits}%"))))
                ->orderBy('code')
                ->paginate(50)
        );
    }
}
