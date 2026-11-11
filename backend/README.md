# Sirkula API (Laravel)

Backend untuk aplikasi Flutter Sirkula. Isinya hanya API, tanpa halaman web. Customer, mitra BSI Ias Toba, dan admin perusahaan memakai API yang sama, dan peran diperiksa di server.

- Laravel 13, PHP 8.3+
- MySQL 8 (Laragon), tes memakai SQLite di memori
- Autentikasi token: Laravel Sanctum

## Menjalankan di laptop (Laragon)

1. Nyalakan MySQL di Laragon, lalu buat database `sirkula` (sekali saja), misalnya lewat SQLyog atau:
   ```bash
   mysql -u root -e "CREATE DATABASE IF NOT EXISTS sirkula CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
   ```
2. Masuk ke folder ini dan pasang pustaka:
   ```bash
   cd backend
   composer install
   ```
3. Salin pengaturan dan buat kunci aplikasi:
   ```bash
   copy .env.example .env
   php artisan key:generate
   ```
   Pengaturan bawaan sudah memakai MySQL `127.0.0.1:3306`, database `sirkula`, user `root` tanpa kata sandi.
4. Buat tabel dan data contoh:
   ```bash
   php artisan migrate:fresh --seed
   ```
5. Jalankan server. Pakai `--host=0.0.0.0` agar HP di jaringan Wi-Fi yang sama bisa mengakses:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   API ada di `http://localhost:8000/api`. Dari emulator Android gunakan `http://10.0.2.2:8000/api`, dari HP gunakan IP laptop, misalnya `http://192.168.1.10:8000/api`.

Menjalankan tes:

```bash
php artisan test
```

## Akun contoh

Semua memakai kata sandi `sirkula123`.

| Peran | Email | Ponsel |
| --- | --- | --- |
| Admin | admin@sirkula.id | 081200000000 |
| Mitra (BSI Ias Toba) | mitra1@example.com | 081200000001 |
| Customer 1 sampai 5 | customer1@example.com … customer5@example.com | 081200000101 … 081200000105 |

Data contoh (riwayat setoran, saldo, permintaan baru) hanya dibuat jika `APP_ENV` bukan `production`.

## Format umum

- Kirim header `Accept: application/json`. Setelah masuk, kirim juga `Authorization: Bearer <token>`.
- Galat validasi: status 422, `{ "message": "...", "errors": { "kolom": ["pesan"] } }`.
- Galat aturan bisnis: status 409 atau 422, `{ "message": "Poin tidak cukup.", "reason": "insufficient_points" }`.
- Daftar berhalaman memakai `data`, `links`, dan `meta` dari Laravel.
- Berat dalam kg dengan satu angka di belakang koma; poin dibulatkan ke bawah oleh server.

## Daftar endpoint

### Akun (`/api/auth`)

| Metode | Rute | Keterangan |
| --- | --- | --- |
| POST | `/auth/login` | `login` (email atau ponsel), `password` → `token`, `user` |
| POST | `/auth/register` | Daftar customer: `name`, `email`, `phone`, `address`, `password` |
| POST | `/auth/forgot-password` | `login`. Selama `APP_DEBUG=true`, kode ikut dikirim di `debug_code` |
| POST | `/auth/reset-password` | `login`, `code` (6 digit), `password` |
| GET | `/auth/me` | Data akun yang sedang masuk |
| POST | `/auth/logout` | Hapus token |

### Semua peran

| Metode | Rute | Keterangan |
| --- | --- | --- |
| GET | `/config` | Data BSI Ias Toba, slot jemput, batas berat, alasan tolak |
| GET | `/waste-types` | Kelompok dan jenis sampah aktif beserta poin per kg |
| GET | `/rewards` | Katalog hadiah aktif |
| GET | `/notifications` | Notifikasi, terbaru dulu, plus jumlah `unread` |
| POST | `/notifications/read-all` | Tandai semua sudah dibaca |

### Customer (`/api/customer`)

| Metode | Rute | Keterangan |
| --- | --- | --- |
| GET | `/summary` | Beranda: saldo, total kg, CO2, poin bulan ini, grafik 6 bulan, jemput aktif |
| PUT | `/profile` | Ubah nama, email, ponsel, alamat |
| PUT | `/password` | `current_password`, `password` |
| GET | `/points` | Riwayat perubahan saldo |
| GET | `/deposits` | Riwayat setoran (`?status=`) |
| POST | `/deposits` | Kirim setoran: `waste_type_id`, `estimated_kg`, `method` (`pickup`/`drop_off`), untuk jemput juga `pickup_date`, `pickup_slot`, `address` |
| GET | `/deposits/{kode}` | Detail dan garis waktu, misalnya `/deposits/STR-261111-01` |
| GET | `/redemptions` | Riwayat penukaran |
| POST | `/redemptions` | Tukar poin: `reward_id`, `address` |

### Mitra (`/api/partner`)

| Metode | Rute | Keterangan |
| --- | --- | --- |
| GET | `/summary` | Beranda: kg bulan ini vs target, customer, poin, jemput hari ini |
| GET | `/deposits?view=requests` | Permintaan baru. Pilihan `view` lain: `pickups`, `ready`, `history` |
| GET | `/deposits/{kode}` | Detail setoran |
| POST | `/deposits/{kode}/accept` | Terima. Jemput wajib `vehicle_id`; boleh ubah `pickup_date`, `pickup_slot` |
| POST | `/deposits/{kode}/reject` | Tolak dengan `reason` |
| POST | `/deposits/{kode}/reschedule` | Ubah `pickup_date`, `pickup_slot`, `vehicle_id` |
| POST | `/deposits/{kode}/depart` | Berangkat menjemput |
| POST | `/deposits/{kode}/weigh` | Catat timbangan: `waste_type_id`, `weighed_kg`, `note`. Poin dihitung server |
| POST | `/deposits/{kode}/correct` | Koreksi berat (FR-M8): `weighed_kg`, `reason`. Hanya setoran terverifikasi, paling lama 7 hari setelah timbang. Selisih poin dikredit atau didebit; saldo tidak boleh minus |
| POST | `/deposits/walk-in` | Customer datang langsung: `customer_id`, `waste_type_id`, `weighed_kg` |
| GET | `/customers/find?q=` | Cari customer lewat ID (`CST-0001`) atau nomor ponsel |
| GET/POST | `/vehicles` | Daftar dan tambah kendaraan (`type`, `plate`) |
| DELETE | `/vehicles/{id}` | Hapus kendaraan dari daftar |

### Admin (`/api/admin`)

| Metode | Rute | Keterangan |
| --- | --- | --- |
| GET | `/summary` | Beranda: kg vs target, CO2, customer aktif, grafik, kg per kelompok |
| GET/PUT | `/bank-sampah` | Data BSI Ias Toba (alamat, jam buka, kontak, target) |
| GET/POST | `/bank-sampah/staff` | Akun petugas mitra |
| PUT | `/bank-sampah/staff/{id}` | Ubah atau nonaktifkan (`is_active`) petugas |
| GET | `/customers?search=` | Daftar customer dan saldonya |
| GET | `/deposits` | Pantau setoran: `search`, `status`, `waste_type_id`, `from`, `to` |
| GET/POST | `/waste-types` | Jenis sampah dan poin per kg |
| PUT | `/waste-types/{id}` | Ubah `points_per_kg`, `is_active`, dan lainnya. Tercatat di log audit |
| GET/POST | `/rewards` | Katalog hadiah |
| PUT | `/rewards/{id}` | Ubah hadiah, termasuk stok dan `is_active` |
| GET | `/redemptions?status=` | Penukaran (`processing`, `shipped`, `done`) |
| POST | `/redemptions/{kode}/ship` | Kirim hadiah dengan `tracking_number` |
| POST | `/redemptions/{kode}/complete` | Tandai selesai |
| GET | `/reports?from=&to=` | Laporan JSON |
| GET | `/reports/export.csv?from=&to=` | Unduh laporan untuk Excel |
| GET | `/reports/link?from=&to=&format=csv\|pdf` | Tautan unduh bertanda tangan (berlaku 10 menit) yang bisa dibuka di peramban tanpa token. `pdf` membuka halaman siap cetak |

## Aturan bisnis yang dijaga server

- Poin = berat timbang × poin per kg, dibulatkan ke bawah. Mitra tidak bisa mengirim angka poin.
- Berat dicatat sampai 0,1 kg, lebih dari 0 dan paling banyak 200 kg per setoran.
- Setoran menyimpan poin per kg saat ditimbang, jadi perubahan tarif tidak mengubah riwayat.
- Saldo tidak boleh negatif. Setiap perubahan saldo tercatat di `point_transactions` dan catatan itu tidak bisa diubah.
- Perubahan poin per kg, data bank sampah, hadiah, dan status penukaran tercatat di `audit_logs`.
- Alamat dan ponsel customer hanya terlihat oleh customer itu sendiri, mitra, dan admin.

## Belum dikerjakan

- Pengiriman kode lupa kata sandi lewat email atau SMS.
- Unggah foto timbangan (kolom `weigh_photo_path` sudah disiapkan).
- Notifikasi push (Firebase); saat ini notifikasi tersimpan dan dibaca lewat `/notifications`.
