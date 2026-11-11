<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTest extends TestCase
{
    use RefreshDatabase;

    protected $seed = true;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::where('email', 'admin@sirkula.id')->firstOrFail();
    }

    public function test_beranda_admin(): void
    {
        $this->actingAs($this->admin)->getJson('/api/admin/summary')
            ->assertOk()
            ->assertJsonPath('partner.name', 'BSI Ias Toba')
            ->assertJsonPath('total_customers', 5)
            ->assertJsonCount(6, 'monthly_kg')
            ->assertJsonStructure(['kg_this_month', 'target_progress', 'co2_this_month_kg', 'active_customers_this_month', 'kg_by_group_this_month']);
    }

    public function test_ubah_data_bank_sampah_dan_tambah_petugas(): void
    {
        $this->actingAs($this->admin)->putJson('/api/admin/bank-sampah', ['hours' => 'Senin–Jumat, 08.00–16.00'])
            ->assertOk()->assertJsonPath('data.hours', 'Senin–Jumat, 08.00–16.00');
        $this->assertDatabaseHas('audit_logs', ['action' => 'partner.updated']);

        $this->actingAs($this->admin)->postJson('/api/admin/bank-sampah/staff', [
            'name' => 'Petugas Dua', 'email' => 'petugas2@example.com', 'phone' => '081277776666', 'password' => 'petugas123',
        ])->assertCreated()->assertJsonPath('data.code', 'MTR-0002')->assertJsonPath('data.role', 'partner');

        $this->postJson('/api/auth/login', ['login' => 'petugas2@example.com', 'password' => 'petugas123'])
            ->assertOk()->assertJsonPath('user.partner.name', 'BSI Ias Toba');
    }

    public function test_kelola_katalog_hadiah(): void
    {
        $id = $this->actingAs($this->admin)->postJson('/api/admin/rewards', [
            'name' => 'Tumbler Bambu', 'category' => 'voucher', 'points' => 15000, 'stock' => 10,
        ])->assertCreated()->assertJsonPath('data.initials', 'TB')->json('data.id');

        $this->actingAs($this->admin)->putJson("/api/admin/rewards/{$id}", ['is_active' => false])
            ->assertOk()->assertJsonPath('data.is_active', false);

        $customer = User::where('email', 'customer1@example.com')->first();
        $names = collect($this->actingAs($customer)->getJson('/api/rewards')->json('data'))->pluck('name');
        $this->assertNotContains('Tumbler Bambu', $names);
    }

    public function test_pantau_setoran_dengan_filter(): void
    {
        $this->actingAs($this->admin)->getJson('/api/admin/deposits?search=Customer 1')
            ->assertOk()
            ->assertJsonPath('data.0.customer.name', 'Customer 1');
        $this->actingAs($this->admin)->getJson('/api/admin/deposits?status=waiting')
            ->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_laporan_json_dan_csv(): void
    {
        $from = now()->subDays(60)->toDateString();
        $this->actingAs($this->admin)->getJson("/api/admin/reports?from={$from}")
            ->assertOk()
            ->assertJsonStructure(['period', 'totals' => ['kg', 'tco2e', 'deposits', 'active_customers', 'points_given'], 'by_type', 'redemptions']);

        $res = $this->actingAs($this->admin)->get("/api/admin/reports/export.csv?from={$from}");
        $res->assertOk();
        $this->assertStringContainsString('Laporan Sirkula', $res->streamedContent());
    }
}
