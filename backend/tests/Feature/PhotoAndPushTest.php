<?php

namespace Tests\Feature;

use App\Models\Deposit;
use App\Models\DeviceToken;
use App\Models\User;
use App\Models\WasteType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request as HttpRequest;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/** Foto timbangan dan notifikasi push. */
class PhotoAndPushTest extends TestCase
{
    use RefreshDatabase;

    protected $seed = true;

    private User $customer;

    private User $partner;

    protected function setUp(): void
    {
        parent::setUp();
        $this->customer = User::where('email', 'customer1@example.com')->firstOrFail();
        $this->partner = User::where('email', 'mitra1@example.com')->firstOrFail();
    }

    private function walkIn(): string
    {
        return $this->actingAs($this->partner)->postJson('/api/partner/deposits/walk-in', [
            'customer_id' => $this->customer->id,
            'waste_type_id' => WasteType::where('code', 'kardus')->first()->id,
            'weighed_kg' => 3,
        ])->assertCreated()->json('data.code');
    }

    public function test_mitra_unggah_foto_dan_customer_melihatnya(): void
    {
        Storage::fake('public');
        $code = $this->walkIn();

        $url = $this->actingAs($this->partner)
            ->post("/api/partner/deposits/{$code}/photo", [
                'photo' => UploadedFile::fake()->image('timbang.jpg', 800, 600),
            ], ['Accept' => 'application/json'])
            ->assertOk()
            ->json('data.weigh_photo_url');
        $this->assertMatchesRegularExpression('#/api/media/weigh-photos/[A-Za-z0-9]{40}\.jpg$#', $url);

        $path = Deposit::where('code', $code)->value('weigh_photo_path');
        Storage::disk('public')->assertExists($path);

        // Customer melihat tautan yang sama di detail setoran.
        $this->actingAs($this->customer)->getJson("/api/customer/deposits/{$code}")
            ->assertJsonPath('data.weigh_photo_url', $url);

        // Foto bisa dibuka tanpa token.
        $this->app['auth']->forgetGuards();
        $this->get(parse_url($url, PHP_URL_PATH))->assertOk();

        // Foto baru mengganti foto lama dan file lama dihapus.
        $this->actingAs($this->partner)->post("/api/partner/deposits/{$code}/photo", [
            'photo' => UploadedFile::fake()->image('ulang.png'),
        ], ['Accept' => 'application/json'])->assertOk();
        Storage::disk('public')->assertMissing($path);
    }

    public function test_foto_ditolak_jika_tidak_sah(): void
    {
        Storage::fake('public');
        $code = $this->walkIn();
        $url = "/api/partner/deposits/{$code}/photo";

        $this->actingAs($this->partner)->post($url, [
            'photo' => UploadedFile::fake()->create('dokumen.pdf', 10, 'application/pdf'),
        ], ['Accept' => 'application/json'])->assertStatus(422)->assertJsonValidationErrors('photo');

        $this->actingAs($this->partner)->post($url, [
            'photo' => UploadedFile::fake()->image('besar.jpg')->size(6000),
        ], ['Accept' => 'application/json'])->assertStatus(422);

        $this->actingAs($this->customer)->post($url, [
            'photo' => UploadedFile::fake()->image('a.jpg'),
        ], ['Accept' => 'application/json'])->assertForbidden();

        $waiting = Deposit::where('status', 'waiting')->first();
        $this->actingAs($this->partner)->post("/api/partner/deposits/{$waiting->code}/photo", [
            'photo' => UploadedFile::fake()->image('a.jpg'),
        ], ['Accept' => 'application/json'])->assertStatus(409);

        $this->get('/api/media/weigh-photos/'.str_repeat('a', 40).'.jpg')->assertNotFound();
        $this->get('/api/media/weigh-photos/..%2F..%2F.env')->assertNotFound();
    }

    public function test_daftar_dan_hapus_token_perangkat(): void
    {
        $this->actingAs($this->customer)->postJson('/api/devices', ['token' => 'tok-1', 'platform' => 'android'])
            ->assertOk()->assertJsonPath('push_enabled', false);
        $this->assertDatabaseHas('device_tokens', ['token' => 'tok-1', 'user_id' => $this->customer->id]);

        // HP yang sama dipakai akun lain: token pindah pemilik.
        $this->actingAs($this->partner)->postJson('/api/devices', ['token' => 'tok-1'])->assertOk();
        $this->assertSame(1, DeviceToken::where('token', 'tok-1')->count());
        $this->assertSame($this->partner->id, DeviceToken::where('token', 'tok-1')->value('user_id'));

        // Customer tidak bisa menghapus token milik orang lain.
        $this->actingAs($this->customer)->deleteJson('/api/devices', ['token' => 'tok-1'])->assertOk();
        $this->assertDatabaseHas('device_tokens', ['token' => 'tok-1']);
        $this->actingAs($this->partner)->deleteJson('/api/devices', ['token' => 'tok-1'])->assertOk();
        $this->assertDatabaseMissing('device_tokens', ['token' => 'tok-1']);
    }

    public function test_notifikasi_dikirim_lewat_fcm_jika_diatur(): void
    {
        // PHP di Windows membutuhkan openssl.cnf untuk membuat kunci.
        $options = ['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA];
        $cnf = dirname(PHP_BINARY).'/extras/ssl/openssl.cnf';
        if (PHP_OS_FAMILY === 'Windows' && is_file($cnf)) {
            $options['config'] = $cnf;
        }
        $key = openssl_pkey_new($options);
        $this->assertNotFalse($key, 'OpenSSL tidak bisa membuat kunci uji.');
        openssl_pkey_export($key, $pem, null, $options);
        $file = tempnam(sys_get_temp_dir(), 'fcm');
        file_put_contents($file, json_encode([
            'project_id' => 'sirkula-uji',
            'client_email' => 'push@sirkula-uji.iam.gserviceaccount.com',
            'private_key' => $pem,
        ]));
        config(['services.fcm.credentials' => $file]);
        $this->withoutDefer();
        Http::fake([
            'oauth2.googleapis.com/*' => Http::response(['access_token' => 'akses-uji']),
            'fcm.googleapis.com/*' => Http::sequence()
                ->push(['name' => 'ok'])
                ->push(['error' => ['status' => 'NOT_FOUND', 'details' => [['errorCode' => 'UNREGISTERED']]]], 404),
        ]);

        DeviceToken::create(['user_id' => $this->customer->id, 'token' => 'hp-aktif']);
        DeviceToken::create(['user_id' => $this->customer->id, 'token' => 'hp-lama']);

        $this->walkIn(); // memicu notifikasi "Poin masuk" ke customer

        Http::assertSent(fn (HttpRequest $r) => str_contains($r->url(), 'projects/sirkula-uji/messages:send')
            && $r->hasHeader('Authorization', 'Bearer akses-uji')
            && $r['message']['token'] === 'hp-aktif'
            && $r['message']['notification']['title'] === 'Poin masuk');
        // Token yang sudah tidak terdaftar dibersihkan.
        $this->assertDatabaseMissing('device_tokens', ['token' => 'hp-lama']);
        $this->assertDatabaseHas('device_tokens', ['token' => 'hp-aktif']);
        @unlink($file);
    }

    public function test_tanpa_firebase_tidak_ada_panggilan_keluar(): void
    {
        config(['services.fcm.credentials' => null]);
        Http::fake();
        DeviceToken::create(['user_id' => $this->customer->id, 'token' => 'hp-aktif']);
        $this->walkIn();
        Http::assertNothingSent();
    }
}
