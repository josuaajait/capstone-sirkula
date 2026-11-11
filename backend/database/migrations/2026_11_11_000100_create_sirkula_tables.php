<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabel inti Sirkula sesuai bagian "Data dan arsitektur" di PRD.
 */
return new class extends Migration
{
    public function up(): void
    {
        // Bank sampah mitra. Rilis pertama hanya satu: BSI Ias Toba.
        Schema::create('partners', function (Blueprint $table) {
            $table->id();
            $table->string('code', 30)->unique();
            $table->string('name');
            $table->string('initials', 4);
            $table->string('address');
            $table->string('area')->nullable();
            $table->string('hours')->nullable();
            $table->string('phone', 20)->nullable();
            $table->decimal('monthly_target_kg', 8, 1)->default(500);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreign('partner_id')->references('id')->on('partners')->nullOnDelete();
        });

        Schema::create('waste_groups', function (Blueprint $table) {
            $table->id();
            $table->string('code', 30)->unique();
            $table->string('name');
            $table->unsignedSmallInteger('sort')->default(0);
            $table->timestamps();
        });

        Schema::create('waste_types', function (Blueprint $table) {
            $table->id();
            $table->foreignId('waste_group_id')->constrained()->restrictOnDelete();
            // Sama dengan nama enum WasteType di aplikasi Flutter, misalnya petBening.
            $table->string('code', 40)->unique();
            $table->string('name');
            $table->string('examples')->nullable();
            $table->unsignedInteger('points_per_kg');
            // Faktor emisi sementara (kg CO2e per kg). Metode tCO2e belum ditetapkan di PRD.
            $table->decimal('co2_per_kg', 6, 3)->default(1.5);
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort')->default(0);
            $table->timestamps();
        });

        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('partner_id')->constrained()->cascadeOnDelete();
            $table->string('type');
            $table->string('plate', 20);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('deposits', function (Blueprint $table) {
            $table->id();
            $table->string('code', 30)->unique(); // STR-YYMMDD-NN
            $table->foreignId('customer_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('partner_id')->constrained()->restrictOnDelete();
            $table->foreignId('waste_type_id')->constrained()->restrictOnDelete();
            $table->decimal('estimated_kg', 6, 1);
            $table->string('method', 16);
            $table->string('status', 16)->index();
            // true jika dicatat mitra untuk customer yang datang langsung (FR-M5).
            $table->boolean('is_walk_in')->default(false);
            $table->date('pickup_date')->nullable();
            $table->string('pickup_slot', 20)->nullable();
            $table->string('address')->nullable();
            $table->text('note')->nullable();
            $table->foreignId('vehicle_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('departed_at')->nullable();
            $table->decimal('weighed_kg', 6, 1)->nullable();
            // Poin per kg yang berlaku saat ditimbang, agar riwayat tidak berubah
            // ketika perusahaan mengubah tarif.
            $table->unsignedInteger('points_per_kg')->nullable();
            $table->unsignedInteger('points_earned')->nullable();
            $table->timestamp('weighed_at')->nullable()->index();
            $table->foreignId('weighed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('weigh_note')->nullable();
            $table->string('weigh_photo_path')->nullable();
            $table->timestamp('rejected_at')->nullable();
            $table->string('reject_reason')->nullable();
            $table->timestamps();
        });

        // Catatan perubahan saldo yang tidak bisa diubah (aturan bisnis "saldo").
        Schema::create('point_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->integer('amount');
            $table->unsignedInteger('balance_after');
            $table->nullableMorphs('source');
            $table->string('description');
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at')->useCurrent()->index();
        });

        Schema::create('rewards', function (Blueprint $table) {
            $table->id();
            $table->string('code', 30)->unique();
            $table->string('initials', 4);
            $table->string('name');
            $table->string('category', 16);
            $table->unsignedInteger('points');
            $table->unsignedInteger('stock')->default(0);
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('redemptions', function (Blueprint $table) {
            $table->id();
            $table->string('code', 30)->unique(); // RDM-YYMMDD-NN
            $table->foreignId('customer_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('reward_id')->constrained()->restrictOnDelete();
            $table->unsignedInteger('points');
            $table->string('address');
            $table->string('status', 16)->index();
            $table->string('tracking_number')->nullable();
            $table->timestamp('shipped_at')->nullable();
            $table->timestamp('done_at')->nullable();
            $table->timestamps();
        });

        // Notifikasi di dalam aplikasi. Nama tabel dibedakan dari tabel
        // notifications bawaan Laravel.
        Schema::create('app_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('body');
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
            $table->index(['user_id', 'read_at']);
        });

        // Log audit untuk perubahan poin per kg, data bank sampah, dan status penukaran.
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('action');
            $table->nullableMorphs('subject');
            $table->json('changes')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('app_notifications');
        Schema::dropIfExists('redemptions');
        Schema::dropIfExists('rewards');
        Schema::dropIfExists('point_transactions');
        Schema::dropIfExists('deposits');
        Schema::dropIfExists('vehicles');
        Schema::dropIfExists('waste_types');
        Schema::dropIfExists('waste_groups');
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['partner_id']);
        });
        Schema::dropIfExists('partners');
    }
};
