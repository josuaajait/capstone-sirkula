<?php

namespace Tests\Feature;

use App\Models\Deposit;
use App\Models\PointTransaction;
use App\Models\Reward;
use App\Models\User;
use App\Models\Vehicle;
use App\Models\WasteType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/** Satu siklus penuh: customer setor, mitra timbang, poin masuk, tukar hadiah, admin kirim. */
class DepositCycleTest extends TestCase
{
    use RefreshDatabase;

    protected $seed = true;

    private User $customer;

    private User $partner;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->customer = User::where('email', 'customer1@example.com')->firstOrFail();
        $this->partner = User::where('email', 'mitra1@example.com')->firstOrFail();
        $this->admin = User::where('email', 'admin@sirkula.id')->firstOrFail();
    }

    public function test_data_contoh_konsisten_dengan_aplikasi(): void
    {
        $this->assertSame(24500, $this->customer->points_balance);
        // Saldo selalu sama dengan transaksi terakhir.
        foreach (User::where('role', 'customer')->get() as $c) {
            $last = PointTransaction::where('user_id', $c->id)->latest('id')->first();
            $this->assertSame($c->points_balance, $last?->balance_after ?? 0);
        }
        $this->actingAs($this->partner)->getJson('/api/partner/deposits?view=requests')
            ->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_siklus_penuh_jemput(): void
    {
        $pet = WasteType::where('code', 'petBening')->first();
        $vehicle = Vehicle::first();

        // 1. Customer meminta jemput.
        $code = $this->actingAs($this->customer)->postJson('/api/customer/deposits', [
            'waste_type_id' => $pet->id,
            'estimated_kg' => 4.8,
            'method' => 'pickup',
            'pickup_date' => now()->addDay()->toDateString(),
            'pickup_slot' => '09.00–11.00',
            'address' => 'Jl. Customer Hijau No. 10, Balige',
        ])->assertCreated()
            ->assertJsonPath('data.status', 'waiting')
            ->assertJsonPath('data.estimated_points', 2400)
            ->json('data.code');
        $this->assertMatchesRegularExpression('/^STR-\d{6}-\d{2}$/', $code);

        // Mitra mendapat notifikasi permintaan baru.
        $this->actingAs($this->partner)->getJson('/api/notifications')
            ->assertJsonPath('data.0.title', 'Permintaan setoran baru');

        // 2. Mitra menerima, berangkat, lalu menimbang.
        $this->actingAs($this->partner)->postJson("/api/partner/deposits/{$code}/accept", ['vehicle_id' => $vehicle->id])
            ->assertOk()->assertJsonPath('data.status', 'scheduled')->assertJsonPath('data.vehicle.plate', 'B 9124 KX');
        $this->actingAs($this->partner)->postJson("/api/partner/deposits/{$code}/accept", ['vehicle_id' => $vehicle->id])
            ->assertStatus(409);
        $this->actingAs($this->partner)->postJson("/api/partner/deposits/{$code}/depart")
            ->assertOk()->assertJsonPath('data.status', 'on_the_way');

        // Mitra tidak bisa mengetik poin (FR-M6).
        $this->actingAs($this->partner)->postJson("/api/partner/deposits/{$code}/weigh", [
            'waste_type_id' => $pet->id, 'weighed_kg' => 5, 'points' => 999999,
        ])->assertUnprocessable()->assertJsonPath('errors.points.0', 'Poin dihitung otomatis oleh sistem.');

        $this->actingAs($this->partner)->postJson("/api/partner/deposits/{$code}/weigh", [
            'waste_type_id' => $pet->id, 'weighed_kg' => 8.44,
        ])->assertOk()
            ->assertJsonPath('data.status', 'verified')
            ->assertJsonPath('data.weighed_kg', 8.4)
            ->assertJsonPath('data.points_earned', 4200);

        // 3. Poin masuk ke saldo customer.
        $this->customer->refresh();
        $this->actingAs($this->customer)->getJson('/api/customer/summary')
            ->assertJsonPath('points_balance', 28700);
        $this->actingAs($this->customer)->getJson('/api/notifications')
            ->assertJsonPath('data.0.title', 'Poin masuk')
            ->assertJsonPath('data.0.body', '+4.200 poin dari setoran botol PET bening 8,4 kg di BSI Ias Toba.');
        $this->actingAs($this->customer)->getJson("/api/customer/deposits/{$code}")
            ->assertJsonPath('data.timeline.4.title', 'Poin masuk ke saldo')
            ->assertJsonPath('data.timeline.4.done', true);

        // 4. Customer menukar hadiah, admin mengirim dan menyelesaikan.
        $reward = Reward::where('code', 'RW-BT')->first();
        $rdm = $this->actingAs($this->customer)->postJson('/api/customer/redemptions', [
            'reward_id' => $reward->id, 'address' => 'Jl. Customer Hijau No. 10, Balige',
        ])->assertCreated()->assertJsonPath('data.status', 'processing')->json('data.code');
        $this->assertSame(10700, $this->customer->fresh()->points_balance);
        $this->assertSame(39, $reward->fresh()->stock);

        $this->actingAs($this->admin)->postJson("/api/admin/redemptions/{$rdm}/complete")->assertStatus(409);
        $this->actingAs($this->admin)->postJson("/api/admin/redemptions/{$rdm}/ship", ['tracking_number' => 'JNE123'])
            ->assertOk()->assertJsonPath('data.status', 'shipped');
        $this->actingAs($this->admin)->postJson("/api/admin/redemptions/{$rdm}/complete")
            ->assertOk()->assertJsonPath('data.status', 'done');
    }

    public function test_tolak_permintaan_dengan_alasan(): void
    {
        $code = Deposit::where('status', 'waiting')->first()->code;
        $this->actingAs($this->partner)->postJson("/api/partner/deposits/{$code}/reject", ['reason' => 'Sampah kotor atau basah'])
            ->assertOk()
            ->assertJsonPath('data.status', 'rejected')
            ->assertJsonPath('data.timeline.1.title', 'Ditolak BSI Ias Toba: Sampah kotor atau basah');
    }

    public function test_customer_datang_langsung_dan_batas_berat(): void
    {
        $can = WasteType::where('code', 'kalengAluminium')->first();
        $found = $this->actingAs($this->partner)->getJson('/api/partner/customers/find?q=0812-0000-0102')
            ->assertOk()->assertJsonPath('data.code', 'CST-0002');
        $before = $found->json('data.points_balance');

        $this->actingAs($this->partner)->postJson('/api/partner/deposits/walk-in', [
            'customer_id' => $found->json('data.id'), 'waste_type_id' => $can->id, 'weighed_kg' => 250,
        ])->assertUnprocessable();

        $this->actingAs($this->partner)->postJson('/api/partner/deposits/walk-in', [
            'customer_id' => $found->json('data.id'), 'waste_type_id' => $can->id, 'weighed_kg' => 1.3,
        ])->assertCreated()
            ->assertJsonPath('data.is_walk_in', true)
            ->assertJsonPath('data.points_earned', 1950)
            ->assertJsonPath('data.timeline.0.title', 'Dicatat langsung di BSI Ias Toba');

        $this->assertSame($before + 1950, User::where('code', 'CST-0002')->first()->points_balance);
    }

    public function test_poin_tidak_cukup_dan_saldo_tidak_negatif(): void
    {
        $sembako = Reward::where('code', 'RW-PS')->first(); // 72.000 poin
        $this->actingAs($this->customer)->postJson('/api/customer/redemptions', [
            'reward_id' => $sembako->id, 'address' => 'Balige',
        ])->assertUnprocessable()->assertJsonPath('reason', 'insufficient_points');
        $this->assertSame(24500, $this->customer->fresh()->points_balance);
    }

    public function test_perubahan_poin_per_kg_hanya_untuk_timbangan_berikutnya(): void
    {
        $pet = WasteType::where('code', 'petBening')->first();
        $old = Deposit::where('status', 'verified')->where('waste_type_id', $pet->id)->first();
        $oldPoints = $old->points_earned;

        $this->actingAs($this->admin)->putJson("/api/admin/waste-types/{$pet->id}", ['points_per_kg' => 600])
            ->assertOk()->assertJsonPath('data.points_per_kg', 600);

        $this->assertSame($oldPoints, $old->fresh()->points_earned);
        $this->assertDatabaseHas('audit_logs', ['action' => 'waste_type.updated', 'subject_id' => $pet->id]);

        $c = User::where('code', 'CST-0003')->first();
        $this->actingAs($this->partner)->postJson('/api/partner/deposits/walk-in', [
            'customer_id' => $c->id, 'waste_type_id' => $pet->id, 'weighed_kg' => 2,
        ])->assertJsonPath('data.points_earned', 1200);
    }

    public function test_mitra_tidak_bisa_menyunting_data_customer_lain_lewat_customer_api(): void
    {
        $other = Deposit::where('customer_id', '!=', $this->customer->id)->first();
        $this->actingAs($this->customer)->getJson("/api/customer/deposits/{$other->code}")->assertNotFound();
    }

    /** Catat timbangan datang langsung untuk customer, kembalikan kode setoran. */
    private function walkIn(float $kg): string
    {
        $pet = WasteType::where('code', 'petBening')->first();

        return $this->actingAs($this->partner)->postJson('/api/partner/deposits/walk-in', [
            'customer_id' => $this->customer->id,
            'waste_type_id' => $pet->id,
            'weighed_kg' => $kg,
        ])->assertCreated()->json('data.code');
    }

    public function test_koreksi_berat_menyesuaikan_poin(): void
    {
        $code = $this->walkIn(8.4); // 4.200 poin
        $balance = $this->customer->refresh()->points_balance;

        // Tarif berubah setelah ditimbang: koreksi tetap memakai tarif lama.
        WasteType::where('code', 'petBening')->update(['points_per_kg' => 999]);

        $this->actingAs($this->partner)->postJson("/api/partner/deposits/{$code}/correct", [
            'weighed_kg' => 4.8,
            'reason' => 'Salah ketik angka timbangan',
        ])->assertOk()
            ->assertJsonPath('data.weighed_kg', 4.8)
            ->assertJsonPath('data.original_weighed_kg', 8.4)
            ->assertJsonPath('data.points_earned', 2400)
            ->assertJsonPath('data.correction_reason', 'Salah ketik angka timbangan');
        $this->assertSame($balance - 1800, $this->customer->refresh()->points_balance);
        $this->assertSame(-1800, PointTransaction::where('user_id', $this->customer->id)->latest('id')->first()->amount);

        // Koreksi kedua menaikkan berat; berat asli tetap tercatat.
        $this->actingAs($this->partner)->postJson("/api/partner/deposits/{$code}/correct", [
            'weighed_kg' => 5,
            'reason' => 'Timbang ulang di depan customer',
        ])->assertOk()->assertJsonPath('data.original_weighed_kg', 8.4)->assertJsonPath('data.points_earned', 2500);
        $this->assertSame($balance - 1700, $this->customer->refresh()->points_balance);
        $this->assertDatabaseHas('audit_logs', ['action' => 'deposit.corrected']);
    }

    public function test_koreksi_ditolak_jika_tidak_sah(): void
    {
        $code = $this->walkIn(2);
        $url = "/api/partner/deposits/{$code}/correct";

        $this->actingAs($this->partner)->postJson($url, ['weighed_kg' => 2, 'reason' => 'tidak berubah'])
            ->assertStatus(422)->assertJsonPath('reason', 'no_change');
        $this->actingAs($this->partner)->postJson($url, ['weighed_kg' => 3])
            ->assertStatus(422)->assertJsonValidationErrors('reason');
        $this->actingAs($this->partner)->postJson($url, ['weighed_kg' => 3, 'reason' => 'mau ubah', 'points' => 99999])
            ->assertStatus(422)->assertJsonValidationErrors('points');
        $this->actingAs($this->customer)->postJson($url, ['weighed_kg' => 3, 'reason' => 'curang dong'])
            ->assertForbidden();

        // Setoran yang belum ditimbang tidak bisa dikoreksi.
        $waiting = Deposit::where('status', 'waiting')->first();
        $this->actingAs($this->partner)->postJson("/api/partner/deposits/{$waiting->code}/correct", [
            'weighed_kg' => 3, 'reason' => 'belum ditimbang',
        ])->assertStatus(409);

        // Lewat 7 hari: harus lewat admin.
        Deposit::where('code', $code)->update(['weighed_at' => now()->subDays(8)]);
        $this->actingAs($this->partner)->postJson($url, ['weighed_kg' => 3, 'reason' => 'sudah lama'])
            ->assertStatus(409)->assertJsonPath('reason', 'correction_expired');
    }

    public function test_koreksi_tidak_boleh_membuat_saldo_negatif(): void
    {
        $code = $this->walkIn(100); // 50.000 poin
        $this->customer->refresh();
        // Customer menghabiskan hampir semua poin.
        app(\App\Services\PointLedger::class)->debit($this->customer, $this->customer->points_balance - 100, null, 'uji');

        $this->actingAs($this->partner)->postJson("/api/partner/deposits/{$code}/correct", [
            'weighed_kg' => 1, 'reason' => 'Salah ketik angka',
        ])->assertStatus(422)->assertJsonPath('reason', 'insufficient_points');
        $this->assertSame(100.0, Deposit::where('code', $code)->first()->weighed_kg);
    }
}
