<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\Role;
use App\Http\Controllers\Controller;
use App\Http\Resources\PartnerResource;
use App\Http\Resources\UserResource;
use App\Models\Partner;
use App\Models\User;
use App\Services\Audit;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

/** Data BSI Ias Toba dan akun petugasnya (FR-P2). */
class BankSampahController extends Controller
{
    public function show(): PartnerResource
    {
        return new PartnerResource(Partner::main());
    }

    public function update(Request $request): PartnerResource
    {
        $partner = Partner::main();
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'initials' => ['sometimes', 'required', 'string', 'max:4'],
            'address' => ['sometimes', 'required', 'string', 'max:255'],
            'area' => ['sometimes', 'nullable', 'string', 'max:100'],
            'hours' => ['sometimes', 'nullable', 'string', 'max:100'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'monthly_target_kg' => ['sometimes', 'required', 'numeric', 'min:0', 'max:100000'],
        ]);
        $partner->fill($data);
        $changes = Audit::diff($partner);
        $partner->save();
        if ($changes) {
            Audit::log($request->user(), 'partner.updated', $partner, $changes);
        }

        return new PartnerResource($partner);
    }

    public function staff(): AnonymousResourceCollection
    {
        return UserResource::collection(
            User::ofRole(Role::Partner)->where('partner_id', Partner::main()->id)->with('partner')->orderBy('code')->get()
        );
    }

    public function storeStaff(Request $request): UserResource
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email', 'max:150', 'unique:users,email'],
            'phone' => ['required', 'string', 'max:20'],
            'password' => ['required', 'string', Password::min(8)->letters()->numbers()],
        ]);
        $phone = $this->uniquePhone($data['phone']);

        $user = User::create([
            'code' => User::nextCode(Role::Partner),
            'role' => Role::Partner,
            'name' => trim($data['name']),
            'email' => mb_strtolower(trim($data['email'])),
            'phone' => $phone,
            'partner_id' => Partner::main()->id,
            'password' => $data['password'],
        ]);
        Audit::log($request->user(), 'partner_staff.created', $user);

        return new UserResource($user->load('partner'));
    }

    public function updateStaff(Request $request, User $user): UserResource
    {
        abort_unless($user->role === Role::Partner, 404);
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'email' => ['sometimes', 'required', 'email', 'max:150', Rule::unique('users')->ignore($user->id)],
            'phone' => ['sometimes', 'required', 'string', 'max:20'],
            'password' => ['sometimes', 'required', 'string', Password::min(8)->letters()->numbers()],
            'is_active' => ['sometimes', 'boolean'],
        ]);
        if (isset($data['phone'])) {
            $data['phone'] = $this->uniquePhone($data['phone'], $user->id);
        }
        if (isset($data['email'])) {
            $data['email'] = mb_strtolower(trim($data['email']));
        }
        $user->fill($data);
        $changes = Audit::diff($user);
        unset($changes['password']);
        $user->save();
        if (($data['is_active'] ?? true) === false) {
            $user->tokens()->delete();
        }
        Audit::log($request->user(), 'partner_staff.updated', $user, $changes);

        return new UserResource($user->load('partner'));
    }

    private function uniquePhone(string $input, ?int $ignore = null): string
    {
        $phone = User::normalizePhone($input);
        if (strlen($phone) < 9 || User::where('phone', $phone)->when($ignore, fn ($q) => $q->whereKeyNot($ignore))->exists()) {
            throw ValidationException::withMessages(['phone' => 'Nomor ponsel tidak valid atau sudah dipakai.']);
        }

        return $phone;
    }
}
