<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            // Kode tampilan, misalnya CST-0001 (customer), MTR-0001 (mitra), ADM-0001 (admin).
            $table->string('code', 20)->unique();
            $table->string('role', 16)->index();
            $table->string('name');
            $table->string('email')->unique();
            // Disimpan dalam bentuk 08xxxxxxxxxx agar 0812…, 62812…, +62 812… dianggap sama.
            $table->string('phone', 20)->unique();
            $table->string('address')->nullable();
            // Saldo poin customer. Setiap perubahan juga dicatat di point_transactions.
            $table->unsignedInteger('points_balance')->default(0);
            // Petugas mitra terhubung ke satu bank sampah (diisi di migrasi partners).
            $table->unsignedBigInteger('partner_id')->nullable()->index();
            $table->boolean('is_active')->default(true);
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('sessions');
    }
};
