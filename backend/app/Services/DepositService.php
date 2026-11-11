<?php

namespace App\Services;

use App\Enums\DepositMethod;
use App\Enums\DepositStatus;
use App\Exceptions\BusinessRuleException;
use App\Models\Deposit;
use App\Models\Partner;
use App\Models\User;
use App\Models\Vehicle;
use App\Models\WasteType;
use App\Support\Fmt;
use Illuminate\Support\Facades\DB;

/**
 * Alur setoran: customer mengirim permintaan, mitra menerima atau menolak,
 * menjemput, lalu menimbang. Poin dihitung di sini, bukan oleh mitra (FR-M6).
 */
class DepositService
{
    /** Batas berat per setoran untuk mencegah salah catat (mitigasi risiko PRD). */
    public const MAX_KG = 200.0;

    /** Slot jemput dari PRD (FR-C4). */
    public const PICKUP_SLOTS = ['09.00–11.00', '13.00–15.00', '15.00–17.00'];

    public function __construct(
        private readonly PointLedger $ledger,
        private readonly Notifier $notifier,
    ) {}

    /** Customer mengirim permintaan setoran (FR-C3 sampai FR-C5). */
    public function create(User $customer, array $data): Deposit
    {
        $partner = Partner::main();
        $type = WasteType::where('is_active', true)->findOrFail($data['waste_type_id']);
        $method = DepositMethod::from($data['method']);

        $deposit = DB::transaction(function () use ($customer, $partner, $type, $method, $data) {
            $now = now();

            return Deposit::create([
                'code' => CodeGenerator::daily('STR', Deposit::class, $now),
                'customer_id' => $customer->id,
                'partner_id' => $partner->id,
                'waste_type_id' => $type->id,
                'estimated_kg' => WasteType::roundKg((float) $data['estimated_kg']),
                'method' => $method,
                'status' => DepositStatus::Waiting,
                'pickup_date' => $method === DepositMethod::Pickup ? $data['pickup_date'] : null,
                'pickup_slot' => $method === DepositMethod::Pickup ? $data['pickup_slot'] : null,
                'address' => $method === DepositMethod::Pickup
                    ? ($data['address'] ?? $customer->address)
                    : null,
                'note' => $this->clean($data['note'] ?? null),
            ]);
        });

        $this->notifier->send(
            $customer,
            'Permintaan setoran terkirim',
            "{$deposit->code} dikirim ke {$partner->name}. Anda akan diberi kabar setelah mitra menerima.",
        );
        $this->notifier->toPartnerStaff(
            $partner,
            'Permintaan setoran baru',
            "{$customer->name} · {$type->name} ±".Fmt::kg($deposit->estimated_kg).', '.mb_strtolower($method->label()).'.',
        );

        return $deposit->load('wasteType');
    }

    /** Mitra menerima permintaan (FR-M2). Penjemputan wajib punya tanggal, slot, dan kendaraan. */
    public function accept(Deposit $deposit, ?string $date = null, ?string $slot = null, ?Vehicle $vehicle = null): Deposit
    {
        $this->assertStatus($deposit, [DepositStatus::Waiting], 'Permintaan ini sudah ditangani.');
        $partner = $deposit->partner;

        $deposit->status = DepositStatus::Scheduled;
        $deposit->accepted_at = now();
        if ($deposit->method === DepositMethod::Pickup) {
            if (! $vehicle) {
                throw new BusinessRuleException('Pilih kendaraan untuk menjemput.', 'vehicle_required');
            }
            $deposit->pickup_date = $date ?? $deposit->pickup_date;
            $deposit->pickup_slot = $slot ?? $deposit->pickup_slot;
            $deposit->vehicle_id = $vehicle->id;
        }
        $deposit->save();

        if ($deposit->method === DepositMethod::Pickup) {
            $this->notifier->send(
                $deposit->customer,
                'Jadwal jemput dikonfirmasi',
                "{$partner->name} akan menjemput ".Fmt::dateShort($deposit->pickup_date).", {$deposit->pickup_slot} WIB dengan {$vehicle->label()}.",
            );
        } else {
            $this->notifier->send(
                $deposit->customer,
                'Permintaan setoran diterima',
                "{$partner->name} menunggu Anda mengantar sampah ke {$partner->address}.",
            );
        }

        return $deposit;
    }

    /** Mitra menolak permintaan dengan alasan (FR-M2). */
    public function reject(Deposit $deposit, string $reason): Deposit
    {
        $this->assertStatus($deposit, [DepositStatus::Waiting], 'Permintaan ini sudah ditangani.');

        $deposit->status = DepositStatus::Rejected;
        $deposit->rejected_at = now();
        $deposit->reject_reason = $reason;
        $deposit->save();

        $this->notifier->send(
            $deposit->customer,
            'Permintaan setoran ditolak',
            "{$deposit->code} ditolak {$deposit->partner->name}: {$reason}.",
        );

        return $deposit;
    }

    /** Ubah jadwal atau kendaraan penjemputan yang sudah diterima (FR-M3). */
    public function reschedule(Deposit $deposit, string $date, string $slot, Vehicle $vehicle): Deposit
    {
        $this->assertPickup($deposit);
        $this->assertStatus($deposit, [DepositStatus::Scheduled, DepositStatus::OnTheWay], 'Jadwal hanya bisa diubah sebelum sampah ditimbang.');

        $deposit->pickup_date = $date;
        $deposit->pickup_slot = $slot;
        $deposit->vehicle_id = $vehicle->id;
        $deposit->save();

        $this->notifier->send(
            $deposit->customer,
            'Jadwal jemput diubah',
            "{$deposit->partner->name} akan menjemput ".Fmt::dateShort($deposit->pickup_date).", {$slot} WIB dengan {$vehicle->label()}.",
        );

        return $deposit;
    }

    /** Mitra berangkat menjemput. */
    public function depart(Deposit $deposit): Deposit
    {
        $this->assertPickup($deposit);
        $this->assertStatus($deposit, [DepositStatus::Scheduled], 'Penjemputan ini tidak bisa diberangkatkan.');

        $deposit->status = DepositStatus::OnTheWay;
        $deposit->departed_at = now();
        $deposit->save();

        $this->notifier->send(
            $deposit->customer,
            'Mitra menuju lokasi',
            "{$deposit->partner->name} sedang menuju alamat Anda dengan ".($deposit->vehicle?->label() ?? 'kendaraan mitra').'.',
        );

        return $deposit;
    }

    /**
     * Catat hasil timbang (FR-M4, FR-M5). Jika $request kosong, setoran dibuat
     * baru untuk customer yang datang langsung tanpa permintaan.
     */
    public function weigh(?Deposit $request, User $customer, WasteType $type, float $kg, ?string $note, User $by): Deposit
    {
        $weighed = WasteType::roundKg($kg);
        if ($weighed <= 0 || $weighed > self::MAX_KG) {
            throw new BusinessRuleException('Berat harus lebih dari 0 dan paling banyak '.Fmt::kg(self::MAX_KG).'.', 'weight_out_of_range');
        }
        if ($request) {
            $this->assertStatus($request, [DepositStatus::Scheduled, DepositStatus::OnTheWay], 'Setoran ini belum diterima atau sudah ditimbang.');
            if ($request->customer_id !== $customer->id) {
                throw new BusinessRuleException('Customer tidak sesuai dengan permintaan.', 'customer_mismatch');
            }
        }

        $deposit = DB::transaction(function () use ($request, $customer, $type, $weighed, $note, $by) {
            $now = now();
            $partner = $request?->partner ?? $by->partner ?? Partner::main();
            $deposit = $request ?? new Deposit([
                'code' => CodeGenerator::daily('STR', Deposit::class, $now),
                'customer_id' => $customer->id,
                'partner_id' => $partner->id,
                'estimated_kg' => $weighed,
                'method' => DepositMethod::DropOff,
                'is_walk_in' => true,
                'accepted_at' => $now,
            ]);

            $deposit->fill([
                'waste_type_id' => $type->id,
                'weighed_kg' => $weighed,
                'points_per_kg' => $type->points_per_kg,
                'points_earned' => WasteType::pointsFor($weighed, $type->points_per_kg),
                'weighed_at' => $now,
                'weighed_by' => $by->id,
                'weigh_note' => $this->clean($note),
                'status' => DepositStatus::Verified,
            ]);
            if ($deposit->method === DepositMethod::Pickup && ! $deposit->departed_at) {
                $deposit->departed_at = $now;
            }
            $deposit->save();

            $this->ledger->credit(
                $customer,
                $deposit->points_earned,
                $deposit,
                "Setoran {$deposit->code}: {$type->name} ".Fmt::kg($weighed),
                $by,
            );

            return $deposit;
        });

        $deposit->setRelation('wasteType', $type);
        $this->notifier->send(
            $customer,
            'Poin masuk',
            Fmt::signedPoints($deposit->points_earned).' poin dari setoran '.self::lowerFirst($type->name).' '.Fmt::kg($weighed)." di {$deposit->partner->name}.",
        );

        return $deposit;
    }

    /** Koreksi hanya boleh dalam jangka ini setelah ditimbang. */
    public const CORRECTION_DAYS = 7;

    /**
     * Koreksi berat yang salah catat (FR-M8). Tarif poin tetap memakai tarif
     * saat ditimbang; selisih poin dikreditkan atau didebit dari saldo
     * customer dan tercatat di riwayat poin serta log audit.
     */
    public function correct(Deposit $deposit, float $kg, string $reason, User $by): Deposit
    {
        $this->assertStatus($deposit, [DepositStatus::Verified], 'Hanya setoran yang sudah ditimbang yang bisa dikoreksi.');
        if ($deposit->weighed_at->lt(now()->subDays(self::CORRECTION_DAYS))) {
            throw new BusinessRuleException('Koreksi hanya bisa dalam '.self::CORRECTION_DAYS.' hari setelah ditimbang. Hubungi admin Sirkula.', 'correction_expired', 409);
        }
        $weighed = WasteType::roundKg($kg);
        if ($weighed <= 0 || $weighed > self::MAX_KG) {
            throw new BusinessRuleException('Berat harus lebih dari 0 dan paling banyak '.Fmt::kg(self::MAX_KG).'.', 'weight_out_of_range');
        }
        if (abs($weighed - $deposit->weighed_kg) < 0.05) {
            throw new BusinessRuleException('Berat baru sama dengan berat lama.', 'no_change');
        }

        $deposit = DB::transaction(function () use ($deposit, $weighed, $reason, $by) {
            $deposit = Deposit::whereKey($deposit->id)->lockForUpdate()->firstOrFail();
            $oldKg = $deposit->weighed_kg;
            $oldPoints = $deposit->points_earned;
            $newPoints = WasteType::pointsFor($weighed, $deposit->points_per_kg);
            $diff = $newPoints - $oldPoints;

            $deposit->fill([
                'original_weighed_kg' => $deposit->original_weighed_kg ?? $oldKg,
                'weighed_kg' => $weighed,
                'points_earned' => $newPoints,
                'corrected_at' => now(),
                'correction_reason' => $reason,
            ]);
            $changes = Audit::diff($deposit);
            $deposit->save();

            $description = "Koreksi {$deposit->code}: ".Fmt::kg($oldKg).' menjadi '.Fmt::kg($weighed);
            if ($diff > 0) {
                $this->ledger->credit($deposit->customer, $diff, $deposit, $description, $by);
            } elseif ($diff < 0) {
                // Gagal dengan "Poin tidak cukup" jika poin sudah terpakai.
                $this->ledger->debit($deposit->customer, -$diff, $deposit, $description, $by);
            }
            Audit::log($by, 'deposit.corrected', $deposit, $changes + ['reason' => [null, $reason]]);

            return $deposit;
        });

        $this->notifier->send(
            $deposit->customer,
            'Berat setoran dikoreksi',
            "{$deposit->code} dikoreksi menjadi ".Fmt::kg($deposit->weighed_kg)." ({$reason}). Poin disesuaikan menjadi ".Fmt::number($deposit->points_earned).'.',
        );

        return $deposit;
    }

    /** "Botol PET bening" menjadi "botol PET bening". */
    public static function lowerFirst(string $text): string
    {
        return mb_strtolower(mb_substr($text, 0, 1)).mb_substr($text, 1);
    }

    private function assertStatus(Deposit $deposit, array $allowed, string $message): void
    {
        if (! in_array($deposit->status, $allowed, true)) {
            throw new BusinessRuleException($message, 'invalid_status', 409);
        }
    }

    private function assertPickup(Deposit $deposit): void
    {
        if ($deposit->method !== DepositMethod::Pickup) {
            throw new BusinessRuleException('Setoran ini diantar sendiri, bukan dijemput.', 'not_pickup', 409);
        }
    }

    private function clean(?string $text): ?string
    {
        $text = $text === null ? null : trim($text);

        return $text === '' ? null : $text;
    }
}
