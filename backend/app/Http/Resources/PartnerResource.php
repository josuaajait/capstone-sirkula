<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Partner */
class PartnerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'name' => $this->name,
            'initials' => $this->initials,
            'address' => $this->address,
            'area' => $this->area,
            'hours' => $this->hours,
            'phone' => $this->phone,
            'monthly_target_kg' => $this->monthly_target_kg,
        ];
    }
}
