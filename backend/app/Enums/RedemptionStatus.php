<?php

namespace App\Enums;

enum RedemptionStatus: string
{
    case Processing = 'processing';
    case Shipped = 'shipped';
    case Done = 'done';

    public function label(): string
    {
        return match ($this) {
            self::Processing => 'Diproses',
            self::Shipped => 'Dikirim',
            self::Done => 'Selesai',
        };
    }
}
