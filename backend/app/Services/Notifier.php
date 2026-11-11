<?php

namespace App\Services;

use App\Enums\Role;
use App\Models\AppNotification;
use App\Models\Partner;
use App\Models\User;

/** Mengirim notifikasi di dalam aplikasi. */
class Notifier
{
    public function send(User $user, string $title, string $body): AppNotification
    {
        return AppNotification::create(['user_id' => $user->id, 'title' => $title, 'body' => $body]);
    }

    /** Kirim ke semua petugas aktif sebuah bank sampah. */
    public function toPartnerStaff(Partner $partner, string $title, string $body): void
    {
        User::ofRole(Role::Partner)
            ->where('partner_id', $partner->id)
            ->where('is_active', true)
            ->each(fn (User $u) => $this->send($u, $title, $body));
    }

    /** Kirim ke semua admin perusahaan yang aktif. */
    public function toAdmins(string $title, string $body): void
    {
        User::ofRole(Role::Admin)
            ->where('is_active', true)
            ->each(fn (User $u) => $this->send($u, $title, $body));
    }
}
