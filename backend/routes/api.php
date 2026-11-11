<?php

use App\Http\Controllers\Api\Admin;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CommonController;
use App\Http\Controllers\Api\Customer;
use App\Http\Controllers\Api\Partner;
use Illuminate\Support\Facades\Route;

/*
| API Sirkula. Semua rute di bawah diawali /api. Aplikasi Flutter mengirim
| token Sanctum di header "Authorization: Bearer <token>".
*/

Route::prefix('auth')->group(function () {
    Route::middleware('throttle:10,1')->group(function () {
        Route::post('login', [AuthController::class, 'login']);
        Route::post('register', [AuthController::class, 'register']);
        Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
        Route::post('reset-password', [AuthController::class, 'resetPassword']);
    });
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('me', [AuthController::class, 'me']);
        Route::post('logout', [AuthController::class, 'logout']);
    });
});

Route::middleware('auth:sanctum')->group(function () {
    // Dipakai semua peran.
    Route::get('config', [CommonController::class, 'config']);
    Route::get('waste-types', [CommonController::class, 'wasteTypes']);
    Route::get('rewards', [CommonController::class, 'rewards']);
    Route::get('notifications', [CommonController::class, 'notifications']);
    Route::post('notifications/read-all', [CommonController::class, 'readNotifications']);

    Route::prefix('customer')->middleware('role:customer')->group(function () {
        Route::get('summary', [Customer\CustomerController::class, 'summary']);
        Route::put('profile', [Customer\CustomerController::class, 'updateProfile']);
        Route::put('password', [Customer\CustomerController::class, 'changePassword']);
        Route::get('points', [Customer\CustomerController::class, 'points']);
        Route::get('deposits', [Customer\DepositController::class, 'index']);
        Route::post('deposits', [Customer\DepositController::class, 'store']);
        Route::get('deposits/{deposit}', [Customer\DepositController::class, 'show']);
        Route::get('redemptions', [Customer\RedemptionController::class, 'index']);
        Route::post('redemptions', [Customer\RedemptionController::class, 'store']);
    });

    Route::prefix('partner')->middleware('role:partner')->group(function () {
        Route::get('summary', [Partner\PartnerController::class, 'summary']);
        Route::get('customers/find', [Partner\PartnerController::class, 'findCustomer']);
        Route::get('vehicles', [Partner\PartnerController::class, 'vehicles']);
        Route::post('vehicles', [Partner\PartnerController::class, 'storeVehicle']);
        Route::delete('vehicles/{vehicle}', [Partner\PartnerController::class, 'deleteVehicle']);
        Route::get('deposits', [Partner\DepositController::class, 'index']);
        Route::post('deposits/walk-in', [Partner\DepositController::class, 'walkIn']);
        Route::get('deposits/{deposit}', [Partner\DepositController::class, 'show']);
        Route::post('deposits/{deposit}/accept', [Partner\DepositController::class, 'accept']);
        Route::post('deposits/{deposit}/reject', [Partner\DepositController::class, 'reject']);
        Route::post('deposits/{deposit}/reschedule', [Partner\DepositController::class, 'reschedule']);
        Route::post('deposits/{deposit}/depart', [Partner\DepositController::class, 'depart']);
        Route::post('deposits/{deposit}/weigh', [Partner\DepositController::class, 'weigh']);
        Route::post('deposits/{deposit}/correct', [Partner\DepositController::class, 'correct']);
    });

    Route::prefix('admin')->middleware('role:admin')->group(function () {
        Route::get('summary', [Admin\DashboardController::class, 'summary']);
        Route::get('bank-sampah', [Admin\BankSampahController::class, 'show']);
        Route::put('bank-sampah', [Admin\BankSampahController::class, 'update']);
        Route::get('bank-sampah/staff', [Admin\BankSampahController::class, 'staff']);
        Route::post('bank-sampah/staff', [Admin\BankSampahController::class, 'storeStaff']);
        Route::put('bank-sampah/staff/{user}', [Admin\BankSampahController::class, 'updateStaff']);
        Route::get('customers', [Admin\CustomerController::class, 'index']);
        Route::get('deposits', [Admin\DepositController::class, 'index']);
        Route::get('deposits/{deposit}', [Admin\DepositController::class, 'show']);
        Route::get('waste-types', [Admin\WasteTypeController::class, 'index']);
        Route::post('waste-types', [Admin\WasteTypeController::class, 'store']);
        Route::put('waste-types/{wasteType}', [Admin\WasteTypeController::class, 'update']);
        Route::get('rewards', [Admin\RewardController::class, 'index']);
        Route::post('rewards', [Admin\RewardController::class, 'store']);
        Route::put('rewards/{reward}', [Admin\RewardController::class, 'update']);
        Route::get('redemptions', [Admin\RedemptionController::class, 'index']);
        Route::post('redemptions/{redemption}/ship', [Admin\RedemptionController::class, 'ship']);
        Route::post('redemptions/{redemption}/complete', [Admin\RedemptionController::class, 'complete']);
        Route::get('reports', [Admin\ReportController::class, 'index']);
        Route::get('reports/export.csv', [Admin\ReportController::class, 'exportCsv']);
        Route::get('reports/link', [Admin\ReportController::class, 'link']);
    });
});

// Unduhan laporan lewat tautan bertanda tangan dari /admin/reports/link,
// agar bisa dibuka di peramban HP tanpa token.
Route::middleware('signed:relative')->prefix('reports')->group(function () {
    Route::get('download.csv', [Admin\ReportController::class, 'exportCsv'])->name('reports.csv');
    Route::get('print', [Admin\ReportController::class, 'printable'])->name('reports.print');
});
