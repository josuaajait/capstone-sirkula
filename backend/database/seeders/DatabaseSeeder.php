<?php

namespace Database\Seeders;

use App\Enums\DepositMethod;
use App\Enums\RewardCategory;
use App\Enums\Role;
use App\Models\Partner;
use App\Models\Reward;
use App\Models\User;
use App\Models\Vehicle;
use App\Models\WasteGroup;
use App\Models\WasteType;
use App\Services\DepositService;
use App\Services\PointLedger;
use App\Services\RedemptionService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

/**
 * Data awal Sirkula. Bagian master (bank sampah, jenis sampah, hadiah, akun
 * admin) dibutuhkan di produksi; bagian riwayat hanya data contoh dan sama
 * dengan data contoh di aplikasi Flutter.
 *
 * Semua akun contoh memakai kata sandi: sirkula123
 */
class DatabaseSeeder extends Seeder
{
    public const DEMO_PASSWORD = 'sirkula123';

    public function run(): void
    {
        $partner = $this->masterData();

        if (! app()->isProduction()) {
            $this->demoData($partner);
        }
    }

    private function masterData(): Partner
    {
        // Alamat lengkap, jam buka, dan kontak masih menunggu konfirmasi pengelola.
        $partner = Partner::create([
            'code' => 'BSI-IAS-TOBA',
            'name' => 'BSI Ias Toba',
            'initials' => 'BI',
            'address' => 'Kabupaten Toba',
            'area' => 'Sumatera Utara',
            'hours' => 'Senin–Sabtu, 08.00–17.00',
            'monthly_target_kg' => 500,
        ]);

        // Poin per kg sesuai tabel usulan PRD; kode sama dengan enum WasteType di Flutter.
        $groups = [
            ['plastik', 'Plastik', [
                ['petBening', 'Botol PET bening', 'Botol air mineral, botol minuman', 500],
                ['plastikKeras', 'Plastik keras', 'Galon, ember, botol sampo', 400],
                ['plastikLembaran', 'Plastik lembaran', 'Kantong kresek, bungkus makanan', 100],
            ]],
            ['kertas', 'Kertas', [
                ['kardus', 'Kardus', 'Kotak kemasan, karton', 300],
                ['kertasPutih', 'Kertas putih', 'HVS, arsip', 300],
                ['kertasCampur', 'Kertas campur', 'Koran, majalah, buku', 200],
            ]],
            ['kaleng', 'Kaleng', [
                ['kalengAluminium', 'Kaleng aluminium', 'Kaleng minuman', 1500],
                ['kalengBesi', 'Kaleng besi', 'Kaleng susu, kaleng sarden', 300],
            ]],
            ['kaca', 'Kaca', [
                ['botolKaca', 'Botol kaca utuh', 'Botol kecap, botol sirup', 100],
                ['pecahanKaca', 'Pecahan kaca', 'Beling', 50],
            ]],
        ];
        foreach ($groups as $g => [$code, $name, $types]) {
            $group = WasteGroup::create(['code' => $code, 'name' => $name, 'sort' => $g]);
            foreach ($types as $t => [$typeCode, $typeName, $examples, $points]) {
                $group->types()->create([
                    'code' => $typeCode,
                    'name' => $typeName,
                    'examples' => $examples,
                    'points_per_kg' => $points,
                    'sort' => $t,
                ]);
            }
        }

        $rewards = [
            ['RW-VB10', 'VB', 'Voucher Belanja Rp10.000', RewardCategory::Voucher, 10000, 120,
                'Voucher belanja digital yang bisa dipakai di minimarket rekanan. Kode voucher dikirim lewat notifikasi aplikasi.'],
            ['RW-BT', 'BT', 'Bibit Tanaman', RewardCategory::Bibit, 18000, 40,
                'Satu paket bibit tanaman sayur atau buah beserta polybag dan media tanam. Dikirim ke alamat Anda.'],
            ['RW-EW25', 'EW', 'Saldo E-Wallet Rp25.000', RewardCategory::EWallet, 25500, 60,
                'Saldo e-wallet senilai Rp25.000 dikirim ke nomor ponsel yang terdaftar di akun Anda.'],
            ['RW-PS', 'PS', 'Paket Sembako', RewardCategory::Sembako, 72000, 15,
                'Paket berisi beras 5 kg, minyak goreng 2 liter, gula 1 kg, dan telur 1 kg. Dikirim ke alamat Anda.'],
        ];
        foreach ($rewards as [$code, $initials, $name, $category, $points, $stock, $description]) {
            Reward::create(compact('code', 'initials', 'name', 'category', 'points', 'stock', 'description'));
        }

        User::create([
            'code' => 'ADM-0001',
            'role' => Role::Admin,
            'name' => 'Admin Sirkula',
            'email' => 'admin@sirkula.id',
            'phone' => '081200000000',
            'password' => self::DEMO_PASSWORD,
        ]);

        return $partner;
    }

    private function demoData(Partner $partner): void
    {
        $deposits = app(DepositService::class);
        $ledger = app(PointLedger::class);
        $redemptions = app(RedemptionService::class);
        $real = Carbon::now();
        $at = fn (int $days, int $hour = 10, int $minute = 0) => $real->copy()->startOfDay()->addDays($days)->setTime($hour, $minute);
        $type = fn (string $code) => WasteType::where('code', $code)->firstOrFail();

        $staff = User::create([
            'code' => 'MTR-0001',
            'role' => Role::Partner,
            'name' => 'Budi Pratama',
            'email' => 'mitra1@example.com',
            'phone' => '081200000001',
            'partner_id' => $partner->id,
            'password' => self::DEMO_PASSWORD,
        ]);
        $pikap = Vehicle::create(['partner_id' => $partner->id, 'type' => 'Pikap', 'plate' => 'B 9124 KX']);
        Vehicle::create(['partner_id' => $partner->id, 'type' => 'Motor roda tiga', 'plate' => 'B 4471 TE']);

        $customers = [];
        foreach ([
            1 => 'Jl. Customer Hijau No. 10, Balige',
            2 => 'Jl. Sisingamangaraja No. 21, Balige, Kabupaten Toba',
            3 => 'Jl. Pagar Batu No. 5, Balige, Kabupaten Toba',
            4 => 'Jl. Raja Sonakmalela No. 14, Laguboti, Kabupaten Toba',
            5 => 'Jl. Patuan Nagari No. 9, Porsea, Kabupaten Toba',
        ] as $n => $address) {
            $customers[$n] = User::create([
                'code' => sprintf('CST-%04d', $n),
                'role' => Role::Customer,
                'name' => "Customer {$n}",
                'email' => "customer{$n}@example.com",
                'phone' => sprintf('0812000001%02d', $n),
                'address' => $address,
                'password' => self::DEMO_PASSWORD,
            ]);
        }

        // Riwayat setoran yang sudah ditimbang: [customer, jenis, kg, hari ke belakang, jam].
        $history = [
            [1, 'petBening', 12.6, 44, 10], [1, 'kardus', 20.0, 30, 10],
            [1, 'kalengAluminium', 2.4, 17, 10], [1, 'botolKaca', 5.2, 10, 10],
            [1, 'petBening', 8.4, 3, 10],
            [2, 'petBening', 18.4, 1, 11], [3, 'kardus', 42.0, 3, 12],
            [5, 'kalengAluminium', 9.6, 5, 13], [4, 'botolKaca', 26.5, 7, 14],
            [5, 'petBening', 31.2, 9, 11], [2, 'kardus', 55.0, 11, 12],
            [3, 'petBening', 22.8, 13, 13], [5, 'kardus', 64.3, 15, 14],
        ];

        // Saldo awal agar saldo akhir mendekati data contoh di aplikasi. Jika
        // poin dari riwayat sudah melebihi target, saldo awal dilewati.
        $targetBalance = [1 => 24500, 2 => 8200, 3 => 15600, 4 => 3100, 5 => 42750];
        $spent = [1 => 10000]; // Customer 1 pernah menukar voucher Rp10.000.
        Carbon::setTestNow($at(-60));
        foreach ($customers as $n => $customer) {
            $earned = 0;
            foreach ($history as [$c, $code, $kg]) {
                if ($c === $n) {
                    $earned += WasteType::pointsFor($kg, $type($code)->points_per_kg);
                }
            }
            $opening = $targetBalance[$n] - $earned + ($spent[$n] ?? 0);
            if ($opening > 0) {
                $ledger->credit($customer, $opening, null, 'Saldo awal (data contoh)');
            }
        }

        foreach ($history as [$c, $code, $kg, $days, $hour]) {
            Carbon::setTestNow($at(-$days, $hour));
            $deposits->weigh(null, $customers[$c], $type($code), $kg, null, $staff);
        }

        Carbon::setTestNow($at(-6));
        $voucher = Reward::where('code', 'RW-VB10')->firstOrFail();
        $redemption = $redemptions->redeem($customers[1], $voucher, $customers[1]->address);
        $redemptions->ship($redemption, 'Kode digital', User::where('role', Role::Admin->value)->firstOrFail());
        Carbon::setTestNow($at(-5));
        $redemptions->complete($redemption->fresh(), User::where('role', Role::Admin->value)->firstOrFail());

        // Customer 1: penjemputan terjadwal dua hari lagi.
        Carbon::setTestNow($at(-1, 14));
        $d = $deposits->create($customers[1], [
            'waste_type_id' => $type('petBening')->id, 'estimated_kg' => 8,
            'method' => DepositMethod::Pickup->value, 'pickup_date' => $at(2)->toDateString(),
            'pickup_slot' => DepositService::PICKUP_SLOTS[0], 'address' => $customers[1]->address,
        ]);
        Carbon::setTestNow($at(-1, 15));
        $deposits->accept($d, null, null, $pikap);

        // Customer 4: penjemputan hari ini yang sudah diterima.
        Carbon::setTestNow($at(-1, 19));
        $d = $deposits->create($customers[4], [
            'waste_type_id' => $type('kardus')->id, 'estimated_kg' => 15,
            'method' => DepositMethod::Pickup->value, 'pickup_date' => $at(0)->toDateString(),
            'pickup_slot' => DepositService::PICKUP_SLOTS[1],
            'note' => 'Kardus sudah diikat, ada di depan pagar.',
        ]);
        $deposits->accept($d, null, null, $pikap);

        // Dua permintaan baru yang menunggu mitra.
        Carbon::setTestNow($real->copy()->subMinutes(150));
        $deposits->create($customers[2], [
            'waste_type_id' => $type('petBening')->id, 'estimated_kg' => 6,
            'method' => DepositMethod::Pickup->value, 'pickup_date' => $at(1)->toDateString(),
            'pickup_slot' => DepositService::PICKUP_SLOTS[0],
            'note' => 'Botol sudah dibilas dan dipipihkan.',
        ]);
        Carbon::setTestNow($real->copy()->subMinutes(65));
        $deposits->create($customers[3], [
            'waste_type_id' => $type('kalengAluminium')->id, 'estimated_kg' => 3.5,
            'method' => DepositMethod::DropOff->value,
        ]);

        Carbon::setTestNow();
    }
}
