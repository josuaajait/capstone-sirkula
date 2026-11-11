<?php

namespace App\Http\Resources;

use App\Enums\DepositMethod;
use App\Enums\DepositStatus;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

/** @mixin \App\Models\Deposit */
class DepositResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $viewer = $request->user();
        // Alamat dan nomor ponsel hanya untuk pihak yang menangani setoran (privasi, PRD).
        $showContact = $viewer && ($viewer->id === $this->customer_id || $viewer->role->value !== 'customer');

        return [
            'id' => $this->id,
            'code' => $this->code,
            'customer' => $this->whenLoaded('customer', fn () => [
                'id' => $this->customer->id,
                'code' => $this->customer->code,
                'name' => $this->customer->name,
                'initials' => $this->customer->initials(),
                'phone' => $showContact ? $this->customer->phone : null,
                'address' => $showContact ? $this->customer->address : null,
            ]),
            'partner' => new PartnerResource($this->whenLoaded('partner')),
            'waste_type' => new WasteTypeResource($this->whenLoaded('wasteType')),
            'estimated_kg' => $this->estimated_kg,
            'estimated_points' => $this->whenLoaded('wasteType', fn () => $this->estimatedPoints()),
            'method' => $this->method->value,
            'method_label' => $this->method->label(),
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'is_walk_in' => $this->is_walk_in,
            'pickup_date' => $this->pickup_date?->toDateString(),
            'pickup_slot' => $this->pickup_slot,
            'address' => $showContact ? $this->address : null,
            'note' => $this->note,
            'vehicle' => $this->whenLoaded('vehicle', fn () => $this->vehicle ? new VehicleResource($this->vehicle) : null),
            'weighed_kg' => $this->weighed_kg,
            'points_per_kg' => $this->points_per_kg,
            'points_earned' => $this->points_earned,
            'weighed_at' => $this->weighed_at,
            'weigh_note' => $this->weigh_note,
            'weigh_photo_url' => $this->weigh_photo_path ? Storage::disk('public')->url($this->weigh_photo_path) : null,
            'reject_reason' => $this->reject_reason,
            'created_at' => $this->created_at,
            'timeline' => $this->whenLoaded('partner', fn () => $this->timeline()),
        ];
    }

    /** Garis waktu sama dengan yang ditampilkan aplikasi Flutter. */
    private function timeline(): array
    {
        $partner = $this->partner->name;
        $step = fn (string $title, $time) => ['title' => $title, 'time' => $time, 'done' => $time !== null];

        if ($this->status === DepositStatus::Rejected) {
            return [
                $step('Permintaan dikirim', $this->created_at),
                $step("Ditolak {$partner}: {$this->reject_reason}", $this->rejected_at),
            ];
        }
        if ($this->is_walk_in) {
            return [
                $step("Dicatat langsung di {$partner}", $this->created_at),
                $step('Sampah diantar & ditimbang', $this->weighed_at),
                $step('Poin masuk ke saldo', $this->weighed_at),
            ];
        }

        $steps = [
            $step('Permintaan dikirim', $this->created_at),
            $step("Diterima {$partner}", $this->accepted_at),
        ];
        if ($this->method === DepositMethod::Pickup) {
            $steps[] = $step('Mitra menuju lokasi', $this->departed_at);
            $steps[] = $step('Sampah diambil & ditimbang', $this->weighed_at);
        } else {
            $steps[] = $step('Sampah diantar & ditimbang', $this->weighed_at);
        }
        $steps[] = $step('Poin masuk ke saldo', $this->weighed_at);

        return $steps;
    }
}
