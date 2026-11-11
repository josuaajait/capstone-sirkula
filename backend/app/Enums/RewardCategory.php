<?php

namespace App\Enums;

enum RewardCategory: string
{
    case Voucher = 'voucher';
    case EWallet = 'e_wallet';
    case Sembako = 'sembako';
    case Bibit = 'bibit';

    public function label(): string
    {
        return match ($this) {
            self::Voucher => 'Voucher',
            self::EWallet => 'E-Wallet',
            self::Sembako => 'Sembako',
            self::Bibit => 'Bibit',
        };
    }
}
