<?php

namespace App\Exceptions;

use Illuminate\Http\JsonResponse;
use RuntimeException;

/**
 * Pelanggaran aturan bisnis yang pesannya boleh ditampilkan ke pengguna,
 * misalnya poin tidak cukup atau permintaan sudah ditangani.
 */
class BusinessRuleException extends RuntimeException
{
    public function __construct(string $message, public readonly string $reason = 'business_rule', public readonly int $status = 422)
    {
        parent::__construct($message);
    }

    public function render(): JsonResponse
    {
        return response()->json(['message' => $this->getMessage(), 'reason' => $this->reason], $this->status);
    }
}
