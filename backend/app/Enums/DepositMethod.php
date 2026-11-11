<?php

namespace App\Enums;

enum DepositMethod: string
{
    case DropOff = 'drop_off';
    case Pickup = 'pickup';

    public function label(): string
    {
        return match ($this) {
            self::DropOff => 'Antar sendiri',
            self::Pickup => 'Dijemput mitra',
        };
    }
}
