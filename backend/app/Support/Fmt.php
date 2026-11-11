<?php

namespace App\Support;

use Carbon\CarbonInterface;

/** Format angka dan tanggal gaya Indonesia, sama dengan lib/app/format.dart. */
class Fmt
{
    private const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    /** 1204 menjadi "1.204". */
    public static function number(int $value): string
    {
        return number_format($value, 0, ',', '.');
    }

    /** +4.200 atau -10.000. */
    public static function signedPoints(int $value): string
    {
        return ($value >= 0 ? '+' : '').self::number($value);
    }

    /** 8.4 menjadi "8,4 kg", 15.0 menjadi "15 kg". */
    public static function kg(float $kg): string
    {
        $rounded = round($kg, 1);
        $text = $rounded == floor($rounded)
            ? number_format($rounded, 0, ',', '.')
            : number_format($rounded, 1, ',', '.');

        return $text.' kg';
    }

    /** "13 Nov". */
    public static function dateShort(CarbonInterface $d): string
    {
        return $d->day.' '.self::MONTHS[$d->month - 1];
    }
}
