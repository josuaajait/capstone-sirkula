<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\WasteType */
class WasteTypeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'group' => $this->whenLoaded('group', fn () => $this->group->code),
            'group_name' => $this->whenLoaded('group', fn () => $this->group->name),
            'name' => $this->name,
            'examples' => $this->examples,
            'points_per_kg' => $this->points_per_kg,
            'co2_per_kg' => $this->co2_per_kg,
            'is_active' => $this->is_active,
        ];
    }
}
