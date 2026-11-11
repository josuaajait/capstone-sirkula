<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Redemption */
class RedemptionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'reward' => new RewardResource($this->whenLoaded('reward')),
            'customer' => $this->whenLoaded('customer', fn () => [
                'code' => $this->customer->code,
                'name' => $this->customer->name,
                'phone' => $this->customer->phone,
            ]),
            'points' => $this->points,
            'address' => $this->address,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'tracking_number' => $this->tracking_number,
            'created_at' => $this->created_at,
            'shipped_at' => $this->shipped_at,
            'done_at' => $this->done_at,
        ];
    }
}
