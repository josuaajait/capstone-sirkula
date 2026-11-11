<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Reward */
class RewardResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'initials' => $this->initials,
            'name' => $this->name,
            'category' => $this->category->value,
            'category_label' => $this->category->label(),
            'points' => $this->points,
            'stock' => $this->stock,
            'description' => $this->description,
            'is_active' => $this->is_active,
        ];
    }
}
