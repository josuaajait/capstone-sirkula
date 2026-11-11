<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\WasteTypeResource;
use App\Models\WasteType;
use App\Services\Audit;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Str;

/**
 * Jenis sampah dan poin per kg (FR-P4). Perubahan tarif hanya berlaku untuk
 * timbangan berikutnya; setoran lama menyimpan tarif saat ditimbang.
 */
class WasteTypeController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return WasteTypeResource::collection(
            WasteType::with('group')->orderBy('waste_group_id')->orderBy('sort')->get()
        );
    }

    public function store(Request $request): WasteTypeResource
    {
        $data = $request->validate([
            'waste_group_id' => ['required', 'integer', 'exists:waste_groups,id'],
            'name' => ['required', 'string', 'max:100', 'unique:waste_types,name'],
            'examples' => ['nullable', 'string', 'max:255'],
            'points_per_kg' => ['required', 'integer', 'min:0', 'max:100000'],
            'co2_per_kg' => ['nullable', 'numeric', 'min:0', 'max:100'],
        ]);
        $data['code'] = Str::camel($data['name']).'-'.Str::lower(Str::random(4));
        $data['sort'] = (int) WasteType::where('waste_group_id', $data['waste_group_id'])->max('sort') + 1;
        $type = WasteType::create($data);
        Audit::log($request->user(), 'waste_type.created', $type, ['points_per_kg' => [null, $type->points_per_kg]]);

        return new WasteTypeResource($type->load('group'));
    }

    public function update(Request $request, WasteType $wasteType): WasteTypeResource
    {
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'examples' => ['sometimes', 'nullable', 'string', 'max:255'],
            'points_per_kg' => ['sometimes', 'required', 'integer', 'min:0', 'max:100000'],
            'co2_per_kg' => ['sometimes', 'required', 'numeric', 'min:0', 'max:100'],
            'is_active' => ['sometimes', 'boolean'],
        ]);
        $wasteType->fill($data);
        $changes = Audit::diff($wasteType);
        $wasteType->save();
        if ($changes) {
            Audit::log($request->user(), 'waste_type.updated', $wasteType, $changes);
        }

        return new WasteTypeResource($wasteType->load('group'));
    }
}
