<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\PointTransaction */
class PointTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'amount' => $this->amount,
            'balance_after' => $this->balance_after,
            'description' => $this->description,
            'created_at' => $this->created_at,
        ];
    }
}
