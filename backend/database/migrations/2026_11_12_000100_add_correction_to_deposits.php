<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Koreksi berat yang salah catat (FR-M8). */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('deposits', function (Blueprint $table) {
            $table->decimal('original_weighed_kg', 6, 1)->nullable()->after('weighed_kg');
            $table->timestamp('corrected_at')->nullable()->after('weighed_at');
            $table->string('correction_reason')->nullable()->after('corrected_at');
        });
    }

    public function down(): void
    {
        Schema::table('deposits', function (Blueprint $table) {
            $table->dropColumn(['original_weighed_kg', 'corrected_at', 'correction_reason']);
        });
    }
};
