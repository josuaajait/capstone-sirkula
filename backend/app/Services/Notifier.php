<?php

namespace App\Services;

use App\Enums\Role;
use App\Models\AppNotification;
use App\Models\Partner;
use App\Models\User;

use function Illuminate\Support\defer;

/**
 * Mengirim notifikasi di dalam aplikasi, lalu push ke HP lewat FCM jika
 * Firebase sudah diatur. Push dikirim setelah respons API selesai agar
 * aplikasi tidak menunggu server Google.
 */
class Notifier
{
    public function __construct(private readonly FcmSender $fcm) {}

    public function send(User $user, string $title, string $body): AppNotification
    {
        $notification = AppNotification::create(['user_id' => $user->id, 'title' => $title, 'body' => $body]);
        if ($this->fcm->enabled()) {
            defer(fn () => $this->fcm->sendToUser($user, $title, $body, ['notification_id' => $notification->id]));
        }

        return $notification;
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
