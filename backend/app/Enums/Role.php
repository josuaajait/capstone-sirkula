<?php

namespace App\Enums;

/** Peran akun (FR-A3). Peran terikat ke akun, tidak dipilih saat masuk. */
enum Role: string
{
    case Customer = 'customer';
    case Partner = 'partner';
    case Admin = 'admin';

    public function codePrefix(): string
    {
        return match ($this) {
            self::Customer => 'CST',
            self::Partner => 'MTR',
            self::Admin => 'ADM',
        };
    }
}
