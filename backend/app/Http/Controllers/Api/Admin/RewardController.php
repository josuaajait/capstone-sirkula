<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\RewardCategory;
use App\Http\Controllers\Controller;
use App\Http\Resources\RewardResource;
use App\Models\Reward;
use App\Services\Audit;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/** Katalog hadiah: nama, kategori, harga poin, dan stok (FR-P5). */
class RewardController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return RewardResource::collection(Reward::orderByDesc('is_active')->orderBy('points')->get());
    }

    public function store(Request $request): RewardResource
    {
        $data = $this->validated($request, creating: true);
        $data['code'] = Reward::nextCode();
        $data['initials'] ??= $this->initials($data['name']);
        $reward = Reward::create($data);
        Audit::log($request->user(), 'reward.created', $reward);

        return new RewardResource($reward);
    }

    public function update(Request $request, Reward $reward): RewardResource
    {
        $reward->fill($this->validated($request, creating: false));
        $changes = Audit::diff($reward);
        $reward->save();
        if ($changes) {
            Audit::log($request->user(), 'reward.updated', $reward, $changes);
        }

        return new RewardResource($reward);
    }

    private function validated(Request $request, bool $creating): array
    {
        $required = $creating ? 'required' : 'sometimes';

        return $request->validate([
            'name' => [$required, 'string', 'max:100'],
            'initials' => ['sometimes', 'nullable', 'string', 'max:4'],
            'category' => [$required, Rule::enum(RewardCategory::class)],
            'points' => [$required, 'integer', 'min:1', 'max:10000000'],
            'stock' => [$required, 'integer', 'min:0', 'max:1000000'],
            'description' => ['sometimes', 'nullable', 'string', 'max:1000'],
            'is_active' => ['sometimes', 'boolean'],
        ]);
    }

    private function initials(string $name): string
    {
        $words = preg_split('/\s+/', trim($name), -1, PREG_SPLIT_NO_EMPTY);

        return mb_strtoupper(mb_substr($words[0] ?? '?', 0, 1).mb_substr($words[1] ?? '', 0, 1));
    }
}
