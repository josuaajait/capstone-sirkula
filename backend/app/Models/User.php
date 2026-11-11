<?php

namespace App\Models;

use App\Enums\Role;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'code', 'role', 'name', 'email', 'phone', 'address',
        'points_balance', 'partner_id', 'is_active', 'password',
    ];

    protected $hidden = ['password', 'remember_token'];

    /** Sama dengan nilai bawaan kolom, agar langsung terisi setelah create(). */
    protected $attributes = ['points_balance' => 0, 'is_active' => true];

    protected function casts(): array
    {
        return [
            'role' => Role::class,
            'points_balance' => 'integer',
            'is_active' => 'boolean',
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function partner(): BelongsTo
    {
        return $this->belongsTo(Partner::class);
    }

    public function deposits(): HasMany
    {
        return $this->hasMany(Deposit::class, 'customer_id');
    }

    public function redemptions(): HasMany
    {
        return $this->hasMany(Redemption::class, 'customer_id');
    }

    public function pointTransactions(): HasMany
    {
        return $this->hasMany(PointTransaction::class);
    }

    public function appNotifications(): HasMany
    {
        return $this->hasMany(AppNotification::class);
    }

    public function scopeOfRole(Builder $query, Role $role): Builder
    {
        return $query->where('role', $role->value);
    }

    /** Inisial untuk avatar, misalnya "Customer 1" menjadi "C1". */
    public function initials(): string
    {
        $parts = preg_split('/\s+/', trim($this->name), -1, PREG_SPLIT_NO_EMPTY);
        if (! $parts) {
            return '?';
        }
        if (count($parts) === 1) {
            return mb_strtoupper(mb_substr($parts[0], 0, 1));
        }

        return mb_strtoupper(mb_substr($parts[0], 0, 1).mb_substr(end($parts), 0, 1));
    }

    /** Menyamakan 0812…, 62812…, dan +62 812… menjadi 0812…. */
    public static function normalizePhone(string $input): string
    {
        $digits = preg_replace('/\D/', '', $input);

        return str_starts_with($digits, '62') ? '0'.substr($digits, 2) : $digits;
    }

    /** Cari akun dari email atau nomor ponsel. */
    public static function findByLogin(string $login): ?self
    {
        $login = trim($login);
        if (str_contains($login, '@')) {
            return static::where('email', mb_strtolower($login))->first();
        }
        $phone = static::normalizePhone($login);

        return strlen($phone) >= 9 ? static::where('phone', $phone)->first() : null;
    }

    /** Kode berikutnya untuk peran ini, misalnya CST-0006. */
    public static function nextCode(Role $role): string
    {
        $prefix = $role->codePrefix().'-';
        $last = static::where('code', 'like', $prefix.'%')->orderByDesc('code')->value('code');
        $n = $last ? ((int) substr($last, strlen($prefix))) + 1 : 1;

        return $prefix.str_pad((string) $n, 4, '0', STR_PAD_LEFT);
    }
}
