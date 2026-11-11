<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    protected $seed = true;

    public function test_login_dengan_email_atau_nomor_ponsel(): void
    {
        $this->postJson('/api/auth/login', ['login' => 'customer1@example.com', 'password' => 'sirkula123'])
            ->assertOk()
            ->assertJsonPath('user.role', 'customer')
            ->assertJsonPath('user.code', 'CST-0001')
            ->assertJsonStructure(['token']);

        // +62 812… dan 0812… dianggap nomor yang sama.
        $this->postJson('/api/auth/login', ['login' => '+62 812 0000 0001', 'password' => 'sirkula123'])
            ->assertOk()
            ->assertJsonPath('user.role', 'partner')
            ->assertJsonPath('user.partner.name', 'BSI Ias Toba');

        $this->postJson('/api/auth/login', ['login' => 'admin@sirkula.id', 'password' => 'sirkula123'])
            ->assertOk()
            ->assertJsonPath('user.role', 'admin');
    }

    public function test_login_gagal_dengan_kata_sandi_salah(): void
    {
        $this->postJson('/api/auth/login', ['login' => 'customer1@example.com', 'password' => 'salah123'])
            ->assertUnprocessable()
            ->assertJsonPath('errors.login.0', 'Email/nomor ponsel atau kata sandi salah.');
    }

    public function test_daftar_customer_baru(): void
    {
        $res = $this->postJson('/api/auth/register', [
            'name' => 'Rina Siahaan',
            'email' => 'Rina@Example.com',
            'phone' => '+62 813 1111 2222',
            'address' => 'Jl. Balige No. 1',
            'password' => 'rahasia123',
        ])->assertCreated()
            ->assertJsonPath('user.code', 'CST-0006')
            ->assertJsonPath('user.email', 'rina@example.com')
            ->assertJsonPath('user.phone', '081311112222')
            ->assertJsonPath('user.points_balance', 0);

        $this->withToken($res->json('token'))->getJson('/api/notifications')
            ->assertJsonPath('data.0.title', 'Selamat datang di Sirkula');
    }

    public function test_daftar_ditolak_untuk_email_perusahaan_dan_data_ganda(): void
    {
        $base = ['name' => 'X', 'phone' => '081399998888', 'address' => 'A', 'password' => 'rahasia123'];

        $this->postJson('/api/auth/register', $base + ['email' => 'x@sirkula.id'])
            ->assertUnprocessable()->assertJsonPath('errors.email.0', 'Email @sirkula.id khusus staf perusahaan.');
        $this->postJson('/api/auth/register', $base + ['email' => 'customer1@example.com'])
            ->assertUnprocessable()->assertJsonPath('errors.email.0', 'Email sudah terdaftar. Silakan masuk.');
        $this->postJson('/api/auth/register', ['email' => 'baru@example.com', 'phone' => '081200000101'] + $base)
            ->assertUnprocessable()->assertJsonPath('errors.phone.0', 'Nomor ponsel sudah terdaftar. Silakan masuk.');
        $this->postJson('/api/auth/register', ['email' => 'baru@example.com', 'password' => 'hanyahuruf'] + $base)
            ->assertUnprocessable()->assertJsonValidationErrors('password');
    }

    public function test_lupa_kata_sandi_dengan_kode_verifikasi(): void
    {
        config(['app.debug' => true]);
        $code = $this->postJson('/api/auth/forgot-password', ['login' => 'customer1@example.com'])
            ->assertOk()->json('debug_code');

        $this->postJson('/api/auth/reset-password', ['login' => 'customer1@example.com', 'code' => '000000', 'password' => 'baru12345'])
            ->assertUnprocessable();
        $this->postJson('/api/auth/reset-password', ['login' => 'customer1@example.com', 'code' => $code, 'password' => 'baru12345'])
            ->assertOk();
        $this->postJson('/api/auth/login', ['login' => 'customer1@example.com', 'password' => 'baru12345'])->assertOk();
    }

    public function test_peran_diperiksa_di_server(): void
    {
        $customer = User::where('email', 'customer1@example.com')->first();
        $this->actingAs($customer)->getJson('/api/admin/summary')->assertForbidden();
        $this->actingAs($customer)->getJson('/api/partner/summary')->assertForbidden();
    }

    public function test_tanpa_token_ditolak(): void
    {
        $this->getJson('/api/customer/summary')
            ->assertUnauthorized()
            ->assertJsonPath('message', 'Sesi berakhir. Silakan masuk lagi.');
    }

    public function test_token_dari_login_bisa_dipakai_dan_dicabut(): void
    {
        $token = $this->postJson('/api/auth/login', ['login' => 'customer1@example.com', 'password' => 'sirkula123'])
            ->json('token');
        $this->withToken($token)->getJson('/api/auth/me')->assertOk()->assertJsonPath('data.code', 'CST-0001');
        $this->withToken($token)->postJson('/api/auth/logout')->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_akun_nonaktif_tidak_bisa_masuk(): void
    {
        User::where('email', 'mitra1@example.com')->update(['is_active' => false]);
        $this->postJson('/api/auth/login', ['login' => 'mitra1@example.com', 'password' => 'sirkula123'])
            ->assertUnprocessable();
    }
}
