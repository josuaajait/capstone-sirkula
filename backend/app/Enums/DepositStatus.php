<?php

namespace App\Enums;

enum DepositStatus: string
{
    case Waiting = 'waiting';
    case Scheduled = 'scheduled';
    case OnTheWay = 'on_the_way';
    case Verified = 'verified';
    case Rejected = 'rejected';

    public function label(): string
    {
        return match ($this) {
            self::Waiting => 'Menunggu mitra',
            self::Scheduled => 'Dijadwalkan',
            self::OnTheWay => 'Mitra menuju lokasi',
            self::Verified => 'Terverifikasi',
            self::Rejected => 'Ditolak',
        };
    }

    /** Status yang masih berjalan (belum selesai ditimbang atau ditolak). */
    public function isActive(): bool
    {
        return $this !== self::Verified && $this !== self::Rejected;
    }
}
