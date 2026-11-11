<?php

namespace App\Http\Resources;

use App\Enums\Role;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\User */
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'role' => $this->role->value,
            'name' => $this->name,
            'initials' => $this->initials(),
            'email' => $this->email,
            'phone' => $this->phone,
            'address' => $this->address,
            'is_active' => $this->is_active,
            'points_balance' => $this->when($this->role === Role::Customer, $this->points_balance),
            'partner' => $this->when($this->role === Role::Partner, fn () => $this->partner ? new PartnerResource($this->partner) : null),
            'created_at' => $this->created_at,
        ];
    }
}
