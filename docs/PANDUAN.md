# Panduan Sirkula: Progres, Riwayat, dan Cara Menjalankan

Panduan ini ditulis untuk orang yang **tidak terbiasa dengan pemrograman**. Isinya menjawab tiga pertanyaan:

1. **Apa yang sudah dikerjakan?** Lihat [bagian 2](#2-yang-sudah-dikerjakan).
2. **Bagaimana pengerjaannya dari awal?** Lihat [bagian 3](#3-riwayat-pengerjaan-dari-awal).
3. **Bagaimana cara menjalankannya?** Lihat [bagian 4 sampai 7](#4-cara-termudah-pasang-apk-di-hp-android).

Repositori proyek: <https://github.com/josuaajait/capstone-sirkula>

*Terakhir diperbarui: 9 November 2026.*

---

## Daftar isi

1. [Ringkasan singkat](#1-ringkasan-singkat)
2. [Yang sudah dikerjakan](#2-yang-sudah-dikerjakan)
3. [Riwayat pengerjaan dari awal](#3-riwayat-pengerjaan-dari-awal)
4. [Cara termudah: pasang APK di HP Android](#4-cara-termudah-pasang-apk-di-hp-android)
5. [Menjalankan dari kode sumber (Windows)](#5-menjalankan-dari-kode-sumber-windows)
6. [Mencoba aplikasi: akun contoh dan alur uji](#6-mencoba-aplikasi-akun-contoh-dan-alur-uji)
7. [Memperbarui ke versi terbaru](#7-memperbarui-ke-versi-terbaru)
8. [Menjalankan backend (nanti)](#8-menjalankan-backend-nanti)
9. [Masalah yang sering muncul](#9-masalah-yang-sering-muncul)
10. [Memantau progres lewat GitHub](#10-memantau-progres-lewat-github)
11. [Daftar istilah](#11-daftar-istilah)

---

## 1. Ringkasan singkat

Sirkula adalah aplikasi yang menghubungkan **customer** (warga yang memilah sampah) dengan **mitra bank sampah**. Customer menyetor sampah, mitra menimbangnya, lalu sistem memberi poin yang bisa ditukar dengan hadiah dari **perusahaan**. Detail lengkapnya ada di [PRD](PRD-Sirkula.md).

Sirkula terdiri dari tiga bagian:

| Bagian | Untuk siapa | Teknologi | Status |
| --- | --- | --- | --- |
| Aplikasi HP | Customer dan mitra bank sampah | Flutter | **Tampilan dan alur utama sudah jadi**, memakai data contoh |
| API (server) | Dipakai aplikasi HP di belakang layar | Laravel | Belum dibuat |
| Peran Admin di aplikasi HP | Staf perusahaan | Flutter (memakai API Laravel) | Belum dibuat. Tidak ada panel admin web |

**Hal penting yang perlu dipahami:**

- Aplikasi HP sudah bisa dicoba dari awal sampai akhir: daftar, masuk, setor sampah, mitra menimbang, poin masuk, lalu tukar hadiah.
- Karena server belum ada, **semua data hanya tersimpan sementara di memori**. Data akan kembali ke kondisi awal setiap kali aplikasi ditutup atau halaman browser dimuat ulang.
- Data di dalamnya, seperti nama bank sampah, hadiah, dan riwayat setoran, adalah **contoh**, bukan data sungguhan.

Bank sampah yang dilayani: **BSI Ias Toba** (satu-satunya mitra).

Target finalisasi proyek: **Jumat, 20 November 2026**.

---

## 2. Yang sudah dikerjakan

Kode kebutuhan seperti `FR-C3` merujuk ke tabel kebutuhan fungsional di [PRD](PRD-Sirkula.md).

### 2.1 Masuk dan akun

| Fitur | Kebutuhan PRD | Status |
| --- | --- | --- |
| Masuk dengan email atau nomor ponsel dan kata sandi | FR-A2 | ✅ Selesai |
| Tampilan berbeda sesuai peran akun (customer atau mitra), bukan dipilih bebas | FR-A3 | ✅ Selesai |
| Email `@sirkula.id` (staf perusahaan) diarahkan ke panel admin | FR-A3 | ✅ Selesai untuk sementara; akan diganti peran Admin di aplikasi |
| Daftar akun customer baru, dengan cek email dan nomor ganda | FR-A4 | ✅ Selesai |
| Aturan kata sandi: minimal 8 karakter, ada huruf dan angka | FR-A4 | ✅ Selesai |
| Lupa kata sandi dengan kode verifikasi | FR-A5 | ✅ Selesai, kode masih tiruan (`123456`) |
| Mitra tidak bisa daftar sendiri, karena didaftarkan perusahaan | FR-P2 | ✅ Sesuai rancangan |
| Layar pembuka (splash) | FR-A1 | ⏳ Belum, prioritas Berikutnya |

### 2.2 Aplikasi customer

Menu bawah: **Beranda, Setor, Jemput, Hadiah, Riwayat**, ditambah profil dan notifikasi di bagian atas.

| Fitur | Kebutuhan PRD | Status |
| --- | --- | --- |
| Beranda: total berat, saldo poin, jadwal aktif, grafik setoran per bulan, dan aktivitas terbaru | FR-C1 | ✅ Selesai |
| Memilih bank sampah mitra, beserta jarak dan jenis sampah yang diterima | FR-C2 | ✅ Selesai |
| Memilih kelompok dan jenis sampah (10 jenis sesuai tabel poin PRD), mengisi perkiraan berat, dan melihat estimasi poin | FR-C3 | ✅ Selesai |
| Memilih dijemput (alamat, tanggal, slot jam) atau antar sendiri | FR-C4 | ✅ Selesai |
| Meninjau ringkasan sebelum mengirim permintaan | FR-C5 | ✅ Selesai |
| Halaman Jemput untuk memantau jadwal dan kendaraan mitra | FR-C6 | ✅ Selesai |
| Riwayat dan detail setoran, termasuk bukti timbang dari mitra | FR-C6 | ✅ Selesai, foto timbang masih contoh |
| Katalog hadiah: Voucher, E-Wallet, Sembako, dan Bibit | FR-C7 | ✅ Selesai |
| Detail hadiah, harga poin, dan sisa saldo setelah ditukar | FR-C8 | ✅ Selesai |
| Konfirmasi penukaran dan alamat pengiriman; saldo tidak bisa minus | FR-C9 | ✅ Selesai |
| Status penukaran dan nomor resi di riwayat | FR-C10 | ✅ Selesai, resi masih contoh |
| Profil, pengaturan, bantuan, dan keluar akun | FR-C11 | ✅ Selesai |
| Notifikasi di dalam aplikasi | Aturan bisnis | ✅ Selesai |

### 2.3 Aplikasi mitra bank sampah

Menu bawah: **Beranda, Permintaan, Jadwal, Timbang, Riwayat**, ditambah profil mitra.

| Fitur | Kebutuhan PRD | Status |
| --- | --- | --- |
| Beranda: berat diterima dibanding target 500 kg per bulan, jumlah customer, jadwal hari ini, dan aktivitas | FR-M1 | ✅ Selesai |
| Daftar permintaan dari customer, dengan tanda jumlah di menu | FR-M2 | ✅ Selesai |
| Menerima permintaan, atau menolak dengan alasan (kotor, tercampur, di luar jangkauan, jadwal penuh) | FR-M2 | ✅ Selesai |
| Mengatur dan mengubah jadwal jemput beserta kendaraan mitra | FR-M3 | ✅ Selesai |
| Mencari customer lewat nomor ponsel atau ID, lalu mencatat jenis dan berat timbang | FR-M4 | ✅ Selesai |
| Mencatat customer yang datang langsung tanpa permintaan | FR-M5 | ✅ Selesai |
| Poin dihitung otomatis oleh sistem dan tidak bisa diubah mitra | FR-M6 | ✅ Selesai |
| Batas berat 200 kg per setoran untuk mencegah salah catat | Risiko PRD | ✅ Selesai |
| Riwayat setoran yang diterima | FR-M7 | ✅ Selesai |
| Koreksi berat yang salah catat | FR-M8 | ⏳ Belum, prioritas Berikutnya |

### 2.4 Aturan bisnis yang sudah diterapkan

- Poin = berat timbang × poin per kg jenis sampah, **dibulatkan ke bawah**.
- Berat dicatat sampai **0,1 kg**, dan isian berat hanya menerima satu angka di belakang koma.
- Angka memakai format Indonesia, misalnya `1.204` dan `8,4 kg`.
- Nomor setoran memakai pola `STR-TTBBHH-NN`, contohnya `STR-261109-01`.
- Tampilan sudah dicek muat di layar HP selebar 360 px.

### 2.5 Pemeriksaan otomatis (tes)

Ada **28 tes otomatis** di folder `test/`. Tes ini memeriksa alur penting, misalnya daftar dan masuk, setor sampah, mitra menimbang lalu poin masuk ke customer, penukaran hadiah, dan pembulatan poin.

Hasil terakhir (9 November 2026): **28 dari 28 tes lulus**, dan pemeriksaan kode `flutter analyze` tidak menemukan masalah.

Sebelumnya ada satu tes yang gagal. Penyebabnya, dua permintaan di data contoh mitra dibuat pada jam tetap, yaitu 08.12 dan 09.40. Jika aplikasi dibuka sebelum jam tersebut, permintaan itu tercatat dibuat di masa depan, sehingga urutan daftar setoran kacau. Sekarang waktunya dihitung mundur dari jam saat aplikasi dibuka.

### 2.6 Yang belum dikerjakan

| Pekerjaan | Keterangan |
| --- | --- |
| API dan basis data (Laravel, MySQL) | Supaya data tersimpan permanen dan bisa dipakai bersama di banyak HP |
| Peran Admin di aplikasi | Kelola data bank sampah, poin per kg, katalog hadiah, proses penukaran, dan laporan PDF/Excel (FR-P1 sampai FR-P8) |
| Menghubungkan aplikasi HP ke API | Kode data aplikasi sudah dipisahkan agar mudah diganti ke API nanti |
| Kirim kode verifikasi sungguhan | Saat ini kodenya selalu `123456` |
| Unggah foto timbangan, notifikasi push, dan angka tCO2e | Angka emisi saat ini hanya perkiraan sementara |
| Layar splash dan koreksi berat | Prioritas Berikutnya di PRD |
| Rilis APK di GitHub | Belum ada versi yang diunggah |

---

## 3. Riwayat pengerjaan dari awal

Urutan pengerjaan sejauh ini:

| Tahap | Tanggal | Yang dikerjakan | Hasil |
| --- | --- | --- | --- |
| 1. Bahan awal | Sebelum 7 Nov 2026 | Rancangan klik (*wireflow*) dibuat di Figma Make: 24 layar dalam 4 jalur | Acuan alur dan tampilan, belum berupa aplikasi |
| 2. Menyusun PRD | 7 Nov 2026 | Wireflow dipelajari, lalu ditulis dokumen kebutuhan: peran, fitur, aturan poin, arsitektur, celah, dan risiko | [docs/PRD-Sirkula.md](PRD-Sirkula.md) beserta diagram alur dan arsitektur |
| 3. Membuat proyek | 8 Nov 2026 | Proyek Flutter kosong dibuat dan diunggah ke GitHub | Commit pertama, `first commit` |
| 4. Panduan awal | 8 Nov 2026 | Ditulis panduan menjalankan aplikasi dan memantau GitHub | Dokumen ini |
| 5. Aplikasi customer | 8 Nov 2026 | Dibuat menu bawah, beranda, setor sampah, katalog dan detail hadiah, serta riwayat. Logo Sirkula dipasang | Folder `lib/customer/` |
| 6. Aplikasi mitra | 8 Nov 2026 | Dibuat beranda mitra, daftar permintaan, jadwal jemput, catat timbangan, dan riwayat. Data mitra disambungkan ke data customer agar permintaan dan poin mengalir di antara keduanya | Folder `lib/partner/` dan tes pertama |
| 7. Pelengkap customer | 8 Nov 2026 | Ditambah profil, pengaturan, bantuan, grafik setoran, halaman jemput, dan detail setoran dengan bukti timbang. Disiapkan juga alat pratinjau versi web | `tool/serve_web.py` |
| 8. Akun | 8 Nov 2026 | Dibuat halaman masuk, daftar, dan lupa kata sandi. Peran diikat ke akun, dan email perusahaan diarahkan ke panel admin | Folder `lib/app/` |
| 9. Tes tambahan | 8 Nov 2026 | Ditambah tes untuk akun, jenis sampah rinci, grafik, isian berat, dan tampilan di layar 360 px | `test/customer_extras_test.dart` |
| 10. Pembaruan dokumen | 9 Nov 2026 | Panduan diperbarui dengan progres, riwayat, dan cara mencoba | Dokumen ini |
| 11. Perbaikan tes | 9 Nov 2026 | Waktu data contoh mitra diperbaiki agar tidak pernah tercatat di masa depan | Semua 28 tes lulus |

> **Catatan:** pekerjaan tahap 4 sampai 11 **belum di-commit dan di-push ke GitHub**. Jadi, untuk saat ini, yang terlihat di GitHub baru commit pertama. Setelah di-push, riwayatnya bisa dilihat di tab Commits (lihat [bagian 10](#10-memantau-progres-lewat-github)).

### Rencana berikutnya

1. Commit dan push pekerjaan aplikasi HP ke GitHub.
2. Bangun API Laravel dan basis data MySQL.
3. Bangun peran Admin perusahaan di aplikasi Flutter.
4. Hubungkan aplikasi HP ke API.
5. Uji coba bersama BSI Ias Toba, lalu finalisasi pada Jumat, 20 November 2026.

### Susunan folder proyek

Bagian ini untuk yang ingin tahu letak kode. Boleh dilewati.

| Folder atau file | Isi |
| --- | --- |
| `lib/main.dart` | Titik awal aplikasi, memilih tampilan customer atau mitra setelah masuk |
| `lib/app/` | Halaman masuk, daftar, lupa kata sandi, akun contoh, warna, dan format angka |
| `lib/customer/` | Semua halaman customer (`pages/`), komponen tampilan (`widgets/`), dan data contoh (`data/`) |
| `lib/partner/` | Semua halaman mitra bank sampah, dengan susunan yang sama |
| `test/` | Tes otomatis |
| `assets/images/` | Logo Sirkula |
| `docs/` | PRD, panduan ini, dan gambar diagram |
| `tool/serve_web.py` | Alat untuk membuka hasil build versi web di browser |
| `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` | Pengaturan bawaan Flutter per platform. Tidak perlu diubah |

---

## 4. Cara termudah: pasang APK di HP Android

Jika Anda hanya ingin **mencoba** aplikasinya, tidak perlu memasang apa pun di komputer. Pengembang akan mengunggah file pemasangan (APK) di halaman Releases GitHub.

1. Buka <https://github.com/josuaajait/capstone-sirkula/releases> di HP Android.
2. Pilih versi paling atas (paling baru).
3. Di bagian **Assets**, ketuk file yang berakhiran `.apk`, misalnya `sirkula-v0.1.0.apk`.
4. Setelah terunduh, buka file tersebut.
5. Jika muncul peringatan *"Pemasangan dari sumber tidak dikenal diblokir"*, ketuk **Setelan**, lalu izinkan browser Anda memasang aplikasi. Kembali dan ketuk **Pasang**.
6. Buka aplikasi **Sirkula** dari layar utama HP, lalu masuk dengan akun contoh di [bagian 6](#6-mencoba-aplikasi-akun-contoh-dan-alur-uji).

> Saat ini halaman Releases **masih kosong**. Gunakan cara di bagian 5, atau minta pengembang mengunggah APK.

> Pengguna iPhone belum bisa memasang langsung. Aplikasi iOS hanya bisa dibangun di komputer Mac, atau dibagikan lewat TestFlight nanti.

---

## 5. Menjalankan dari kode sumber (Windows)

Cara ini diperlukan jika Anda ingin melihat **versi paling baru** yang belum dirilis, atau ikut mengembangkan. Pemasangan pertama memakan waktu sekitar 30–60 menit dan butuh ruang kosong sekitar 10 GB.

### 5.1 Pasang Git

Git dipakai untuk mengunduh kode dari GitHub.

1. Buka <https://git-scm.com/download/win>.
2. Unduh **64-bit Git for Windows Setup**, lalu jalankan.
3. Klik **Next** terus sampai **Install**, biarkan semua pilihan bawaan.

### 5.2 Pasang Visual Studio Code

VS Code adalah aplikasi untuk membuka kode dan menjalankan perintah.

1. Buka <https://code.visualstudio.com/>, klik **Download for Windows**, lalu pasang.
2. Buka VS Code. Klik ikon kotak-kotak di sisi kiri (**Extensions**), atau tekan `Ctrl+Shift+X`.
3. Cari **Flutter**, lalu klik **Install** pada ekstensi buatan *Dart Code*. Ekstensi Dart ikut terpasang otomatis.

### 5.3 Pasang Flutter SDK

1. Di VS Code, tekan `Ctrl+Shift+P`, ketik **Flutter: New Project**, lalu tekan Enter.
2. Muncul tawaran mengunduh Flutter SDK. Klik **Download SDK**.
3. Pilih folder tanpa spasi, misalnya `C:\dev`. **Jangan** pilih `C:\Program Files` atau folder yang namanya berspasi.
4. Tunggu sampai selesai (bisa 5–15 menit). Saat ditanya apakah ingin menambahkan Flutter ke PATH, klik **Add SDK to PATH**.
5. Tutup lalu buka kembali VS Code. Batalkan pembuatan proyek baru jika masih terbuka.

Cara lain: ikuti panduan resmi di <https://docs.flutter.dev/get-started/install/windows>.

### 5.4 Pilih tempat aplikasi akan tampil

Pilih **salah satu**. Pilihan A paling mudah.

**A. Di browser Chrome (paling mudah)**

Cukup pasang Google Chrome dari <https://www.google.com/chrome/>. Aplikasi akan tampil di jendela browser.

> Tips: tekan `F12` lalu `Ctrl+Shift+M` di Chrome agar tampilannya seukuran layar HP.

**B. Di HP Android sungguhan**

1. Di HP, buka **Setelan → Tentang ponsel**, lalu ketuk **Nomor versi** (atau *Build number*) 7 kali sampai muncul tulisan *"Anda sekarang developer"*.
2. Kembali ke **Setelan → Sistem → Opsi pengembang**, lalu aktifkan **USB debugging**.
3. Sambungkan HP ke komputer dengan kabel USB. Jika muncul pertanyaan *"Izinkan USB debugging?"* di HP, ketuk **Izinkan**.
4. Pilihan ini juga membutuhkan Android Studio (lihat pilihan C, langkah 1–3) agar alat Android terpasang.

**C. Di emulator (HP tiruan di komputer)**

1. Unduh Android Studio dari <https://developer.android.com/studio>, lalu pasang dengan pilihan bawaan.
2. Buka Android Studio dan selesaikan wizard awal (pilih **Standard**). Tunggu unduhan komponen selesai.
3. Di layar awal, klik **More Actions → SDK Manager → SDK Tools**, centang **Android SDK Command-line Tools**, lalu klik **Apply**.
4. Kembali ke layar awal, klik **More Actions → Virtual Device Manager → Create Device**. Pilih misalnya **Pixel 7**, klik **Next**, unduh versi Android yang disarankan, lalu **Finish**.
5. Klik tombol ▶ di samping perangkat tersebut untuk menyalakan emulator.

### 5.5 Periksa pemasangan

1. Di VS Code, buka terminal dengan menu **Terminal → New Terminal**.
2. Ketik perintah berikut, lalu tekan Enter:

   ```bash
   flutter doctor
   ```

3. Baca hasilnya. Tanda **✓** berarti siap, tanda **✗** atau **!** berarti ada yang kurang.
   - Untuk pilihan A, cukup baris **Flutter** dan **Chrome** yang bertanda ✓.
   - Untuk pilihan B atau C, baris **Android toolchain** juga harus ✓.
   - Jika diminta menerima lisensi Android, jalankan `flutter doctor --android-licenses`, lalu ketik `y` dan Enter untuk setiap pertanyaan.
   - Baris **Visual Studio** boleh diabaikan, karena hanya diperlukan untuk aplikasi desktop Windows.

### 5.6 Unduh kode Sirkula

Di terminal VS Code, jalankan perintah ini satu per satu:

```bash
cd C:\dev
```

```bash
git clone https://github.com/josuaajait/capstone-sirkula.git
```

Jika repositori bersifat privat, akan muncul jendela masuk GitHub. Masuk dengan akun yang sudah diundang oleh pengembang (lihat [bagian 10.1](#101-siapkan-akun)).

Setelah selesai, buka foldernya di VS Code lewat menu **File → Open Folder**, lalu pilih `C:\dev\capstone-sirkula`. Jika muncul pertanyaan *"Do you trust the authors?"*, klik **Yes, I trust the authors**.

### 5.7 Jalankan aplikasi

1. Buka terminal baru (**Terminal → New Terminal**). Pastikan terminal sudah berada di folder `capstone-sirkula`.
2. Unduh pustaka yang dibutuhkan aplikasi:

   ```bash
   flutter pub get
   ```

3. Jalankan aplikasi sesuai pilihan di langkah 5.4:

   | Pilihan | Perintah |
   | --- | --- |
   | A. Chrome | `flutter run -d chrome` |
   | B/C. HP atau emulator | `flutter run` |

   Untuk melihat daftar perangkat yang terdeteksi, jalankan `flutter devices`.

4. Pertama kali dijalankan, prosesnya bisa memakan 2–10 menit. Setelah itu halaman **Masuk** Sirkula akan muncul. Lanjutkan ke [bagian 6](#6-mencoba-aplikasi-akun-contoh-dan-alur-uji).

Saat aplikasi berjalan, Anda bisa menekan tombol berikut di terminal:

| Tombol | Fungsi |
| --- | --- |
| `r` | Muat ulang cepat setelah kode berubah |
| `R` | Mulai ulang aplikasi dari awal (data contoh kembali ke kondisi awal) |
| `q` | Hentikan aplikasi |

### 5.8 Menjalankan tes otomatis (opsional)

Untuk memeriksa apakah fitur-fitur utama masih berjalan benar:

```bash
flutter test
```

Di akhir akan muncul `All tests passed!` jika semua lulus, atau `Some tests failed.` beserta nama tes yang gagal.

### 5.9 Membuka versi web tanpa mode pengembang (opsional)

Cara ini menghasilkan versi web yang lebih ringan dan bisa dibuka berkali-kali tanpa menunggu `flutter run`. Dibutuhkan Python dari <https://www.python.org/downloads/>.

```bash
flutter build web
```

```bash
python tool/serve_web.py
```

Lalu buka <http://localhost:8765> di browser. Tekan `Ctrl+C` di terminal untuk menghentikannya.

### 5.10 Membuat file APK sendiri (opsional)

Untuk membagikan aplikasi ke HP lain tanpa kabel:

```bash
flutter build apk --release
```

File hasilnya ada di `build\app\outputs\flutter-apk\app-release.apk`. Kirim file ini ke HP, lalu pasang seperti di bagian 4.

---

## 6. Mencoba aplikasi: akun contoh dan alur uji

### 6.1 Akun contoh

Di halaman Masuk ada tombol akun contoh yang mengisi data secara otomatis. Anda juga bisa mengetiknya sendiri:

| Peran | Email | Nomor ponsel | Kata sandi |
| --- | --- | --- | --- |
| Customer | `customer1@example.com` | `081200000101` | `sirkula123` |
| Mitra bank sampah (BSI Ias Toba) | `mitra1@example.com` | `081200000001` | `sirkula123` |

Hal lain yang bisa dicoba:

- **Daftar akun baru:** klik **Daftar sebagai customer** di halaman Masuk. Akun baru selalu berperan customer, dan mulai dengan saldo serta riwayat kosong.
- **Lupa kata sandi:** klik **Lupa kata sandi?**, masukkan email akun, lalu isi kode verifikasi `123456`.
- **Akun perusahaan:** email apa pun yang berakhiran `@sirkula.id` saat ini masih diarahkan ke panel admin. Panel web tidak jadi dibuat; staf perusahaan nanti masuk sebagai peran Admin di aplikasi.

### 6.2 Alur uji satu siklus penuh

Ikuti langkah ini **tanpa menutup aplikasi atau memuat ulang browser**, karena data hanya tersimpan sementara.

**Sebagai customer**

1. Masuk dengan akun **Customer**.
2. Lihat **Beranda**: saldo poin, total berat, dan grafik.
3. Buka menu **Setor**, pilih bank sampah, pilih jenis sampah (misalnya *Botol PET bening*), lalu isi berat, misalnya `5`. Perhatikan estimasi poinnya.
4. Pilih **Dijemput**, isi alamat, tanggal, dan jam. Tinjau ringkasan, lalu kirim.
5. Buka menu **Riwayat**. Setoran baru berstatus menunggu mitra.
6. Buka profil di kanan atas, lalu klik **Keluar**.

**Sebagai mitra**

7. Masuk dengan akun **Mitra**.
8. Buka menu **Permintaan**. Permintaan dari customer tadi muncul di sini. Klik **Terima & Jadwalkan**, lalu pilih jadwal dan kendaraan.
9. Buka menu **Jadwal** untuk melihat penjemputan yang sudah diterima.
10. Buka menu **Timbang**, pilih setoran tersebut, lalu isi berat hasil timbang, misalnya `4,8`. Perhatikan bahwa poin dihitung otomatis dan tidak bisa diubah. Simpan.
11. Keluar dari akun mitra.

**Kembali sebagai customer**

12. Masuk lagi dengan akun **Customer**. Saldo poin bertambah, dan ada notifikasi poin masuk.
13. Buka menu **Hadiah**, pilih hadiah yang terjangkau, isi alamat pengiriman, lalu klik **Tukar Sekarang**. Saldo berkurang, dan penukaran tampil di **Riwayat**.

Coba juga di sisi mitra: **tolak** sebuah permintaan dengan alasan, atau catat timbangan untuk customer yang **datang langsung** dengan mencari nomor ponselnya.

---

## 7. Memperbarui ke versi terbaru

Setiap kali pengembang menambahkan fitur, Anda bisa mengambil versi terbaru tanpa mengunduh ulang semuanya. Buka folder proyek di VS Code, lalu jalankan:

```bash
git pull
```

```bash
flutter pub get
```

```bash
flutter run -d chrome
```

> Jangan mengubah file kode jika Anda hanya ingin mencoba. Jika `git pull` menolak karena ada perubahan, jalankan `git stash` terlebih dahulu, lalu ulangi `git pull`.

---

## 8. Menjalankan backend (nanti)

> Bagian ini **belum bisa dijalankan**, karena API Laravel belum dibuat. Laravel hanya dipakai untuk backend, tanpa halaman web. Langkah di bawah adalah gambaran umum dan akan diperbarui setelah bagian tersebut ada di repositori.

Backend membutuhkan program tambahan:

| Program | Fungsi | Cara termudah memasang |
| --- | --- | --- |
| PHP dan Composer | Menjalankan Laravel | [Laravel Herd](https://herd.laravel.com/windows) memasang keduanya sekaligus |
| MySQL | Basis data | Laragon atau XAMPP, atau MySQL bawaan Herd Pro |

Gambaran langkahnya nanti:

1. Masuk ke folder backend, misalnya `cd backend`.
2. Pasang pustaka: `composer install`.
3. Salin file pengaturan: `copy .env.example .env`, lalu isi nama, pengguna, dan kata sandi basis data di file `.env`.
4. Buat kunci aplikasi: `php artisan key:generate`.
5. Buat tabel dan data contoh: `php artisan migrate --seed`.
6. Jalankan server: `php artisan serve`. API bisa dicoba di `http://localhost:8000/api`.
7. Arahkan aplikasi Flutter ke alamat server tersebut sesuai petunjuk di README nanti.

---

## 9. Masalah yang sering muncul

| Pesan atau gejala | Penyebab | Solusi |
| --- | --- | --- |
| `'flutter' is not recognized` | Flutter belum masuk PATH | Tutup semua jendela VS Code dan terminal, lalu buka lagi. Jika masih gagal, ulangi langkah 5.3 |
| `'C:\Users\...' is not recognized` saat menjalankan perintah Flutter | Flutter dipasang di folder yang namanya berspasi | Pindahkan atau pasang ulang Flutter di folder tanpa spasi, misalnya `C:\dev\flutter` |
| `'git' is not recognized` | Git belum terpasang | Ulangi langkah 5.1, lalu buka ulang VS Code |
| `No devices found` | Tidak ada HP, emulator, atau Chrome | Nyalakan emulator, sambungkan HP, atau gunakan `flutter run -d chrome` |
| HP tidak muncul di `flutter devices` | USB debugging belum aktif atau belum diizinkan | Ulangi langkah 5.4 B, coba kabel lain, dan pilih mode **Transfer file** di HP |
| `Android license status unknown` | Lisensi belum diterima | Jalankan `flutter doctor --android-licenses` |
| Muncul error `pub get failed` | Koneksi internet bermasalah | Periksa internet, lalu ulangi `flutter pub get` |
| `Building with plugins requires symlink support` | Mode pengembang Windows belum aktif | Buka **Settings → System → For developers**, aktifkan **Developer Mode** |
| Proses `flutter run` sangat lama | Normal saat pertama kali | Tunggu sampai selesai. Jalankan berikutnya akan jauh lebih cepat |
| Kata sandi ditolak | Salah ketik, atau akun baru hilang setelah aplikasi dimuat ulang | Gunakan akun contoh di bagian 6.1, atau daftar ulang |
| Setoran atau poin yang tadi dibuat hilang | Data hanya tersimpan sementara | Normal untuk saat ini. Ulangi alur tanpa menutup aplikasi |
| `build\web belum ada` saat menjalankan `serve_web.py` | Versi web belum dibangun | Jalankan `flutter build web` terlebih dahulu |
| Ada error aneh setelah `git pull` | Sisa hasil build lama | Jalankan `flutter clean`, lalu `flutter pub get`, dan coba lagi |

Jika masih gagal, salin seluruh pesan error di terminal, lalu kirimkan ke pengembang atau buat Issue di GitHub (lihat [bagian 10.4](#104-cara-membaca-dan-memakai-setiap-bagian)).

---

## 10. Memantau progres lewat GitHub

GitHub adalah tempat kode Sirkula disimpan. Dari sana Anda bisa melihat apa saja yang sudah dikerjakan, apa yang sedang dikerjakan, dan apa yang belum, **tanpa perlu menjalankan aplikasi**.

### 10.1 Siapkan akun

1. Daftar akun gratis di <https://github.com/signup>.
2. Kirim nama pengguna GitHub Anda ke pengembang.
3. Jika repositori privat, pengembang akan mengundang Anda sebagai *collaborator*. Buka email undangan dari GitHub, lalu klik **Accept invitation**.
4. Buka <https://github.com/josuaajait/capstone-sirkula>.

### 10.2 Nyalakan notifikasi

Agar mendapat kabar setiap ada perubahan:

1. Di halaman repositori, klik tombol **Watch** di kanan atas.
2. Pilih **All Activity** untuk semua kabar, atau **Custom → Issues, Pull requests, Releases** untuk kabar penting saja.
3. Kabar akan dikirim ke email Anda dan tampil di ikon lonceng 🔔 GitHub.

Pasang juga aplikasi **GitHub** untuk Android atau iOS agar bisa memantau dari HP.

### 10.3 Peta halaman repositori

| Tab | Yang bisa dilihat | Pertanyaan yang dijawab |
| --- | --- | --- |
| **Code** | File proyek dan README | Apa isi proyek ini? |
| **Commits** (klik tulisan *"N commits"* di tab Code) | Riwayat perubahan, lengkap dengan tanggal dan penjelasan | Apa yang dikerjakan hari ini atau minggu ini? |
| **Issues** | Daftar tugas, fitur, dan laporan bug | Apa saja yang belum selesai? |
| **Pull requests** | Perubahan yang sedang diajukan dan menunggu diperiksa | Fitur apa yang hampir jadi? |
| **Projects** | Papan tugas berkolom *Todo → In Progress → Done* | Bagaimana gambaran progres secara keseluruhan? |
| **Milestones** (di dalam tab Issues) | Kelompok tugas untuk satu target, dengan persentase selesai | Seberapa dekat dengan finalisasi 20 November? |
| **Actions** | Hasil pemeriksaan otomatis setiap ada perubahan | Apakah kode terbaru berjalan tanpa error? |
| **Releases** (di sisi kanan tab Code) | Versi aplikasi yang siap dicoba, beserta file APK | Versi mana yang bisa saya pasang? |
| **Insights → Pulse / Contributors** | Ringkasan aktivitas per minggu dan per orang | Seberapa aktif proyek ini? |

Selain di GitHub, bagian [2. Yang sudah dikerjakan](#2-yang-sudah-dikerjakan) dan [3. Riwayat pengerjaan](#3-riwayat-pengerjaan-dari-awal) di dokumen ini juga akan diperbarui setiap ada kemajuan.

### 10.4 Cara membaca dan memakai setiap bagian

**Melihat riwayat pekerjaan (Commits)**

1. Di tab **Code**, klik tulisan **commits** dengan ikon jam di atas daftar file.
2. Setiap baris adalah satu perubahan: judul, siapa yang mengubah, dan kapan.
3. Klik judulnya untuk melihat file apa saja yang berubah. Baris hijau berarti ditambah, merah berarti dihapus.

**Memantau tugas (Issues)**

1. Buka tab **Issues**. Tugas yang masih berjalan ada di **Open**, yang sudah selesai ada di **Closed**.
2. Gunakan label untuk menyaring, misalnya `customer`, `mitra`, `perusahaan`, atau `bug`.
3. Untuk melaporkan masalah atau memberi masukan, klik **New issue**, tulis judul yang jelas, jelaskan langkah yang Anda lakukan, lalu lampirkan tangkapan layar. Klik **Submit new issue**.
4. Anda bisa berkomentar di issue mana pun untuk bertanya atau memberi masukan.

**Melihat papan progres (Projects)**

1. Buka tab **Projects**, lalu pilih papan proyek Sirkula.
2. Setiap kartu adalah satu tugas. Posisi kolom menunjukkan statusnya:
   - **Todo**: belum dikerjakan
   - **In Progress**: sedang dikerjakan
   - **Review**: selesai dan sedang diperiksa
   - **Done**: selesai

**Melihat target rilis (Milestones)**

1. Buka tab **Issues**, lalu klik **Milestones**.
2. Pilih milestone, misalnya *Rilis 1 – 8 Des 2026*. Bilah hijau dan persentase menunjukkan berapa banyak tugas yang sudah selesai.

**Memeriksa kesehatan kode (Actions)**

Di halaman utama, di samping commit terakhir, ada tanda:

| Tanda | Arti |
| --- | --- |
| ✅ centang hijau | Pemeriksaan otomatis lulus |
| ❌ silang merah | Ada error, pengembang perlu memperbaikinya |
| 🟡 titik kuning | Pemeriksaan sedang berjalan |

### 10.5 Ritme pemantauan yang disarankan

| Kapan | Yang dicek |
| --- | --- |
| Setiap hari, 2 menit | Email notifikasi GitHub, atau ikon lonceng |
| Setiap minggu | Papan **Projects**, persentase **Milestone**, dan bagian 2 dokumen ini. Bandingkan dengan minggu lalu |
| Setiap ada rilis | Unduh APK dari **Releases**, coba alur di bagian 6.2, lalu laporkan temuan di **Issues** |

### 10.6 Catatan untuk pengembang

Agar pemantauan di atas berjalan, siapkan hal berikut di repositori:

- [ ] Commit dan push pekerjaan aplikasi HP yang sudah ada.
- [ ] Buat milestone **Rilis 1 – 8 Des 2026** dan hubungkan ke setiap issue fitur Wajib.
- [ ] Buat satu issue per kebutuhan di PRD, dengan ID pada judul, misalnya `FR-C3 Pilih jenis sampah dan estimasi poin`. Tutup issue yang sudah selesai sesuai bagian 2.
- [ ] Buat label `customer`, `mitra`, `perusahaan`, `backend`, `bug`, dan `wajib`/`berikutnya`.
- [ ] Buat papan **Projects** dengan kolom Todo, In Progress, Review, dan Done.
- [ ] Tulis pesan commit yang jelas, dan sebut nomor issue, misalnya `Tambah layar pilih bank sampah (#12)`.
- [ ] Tambahkan GitHub Actions yang menjalankan `flutter analyze` dan `flutter test` di setiap perubahan.
- [ ] Unggah APK ke **Releases** setiap selesai satu tahap, misalnya setiap minggu.
- [ ] Perbarui bagian 2 dan 3 dokumen ini setiap ada kemajuan.
- [ ] Undang pemantau sebagai collaborator jika repositori privat.

---

## 11. Daftar istilah

| Istilah | Arti sederhana |
| --- | --- |
| Repositori (repo) | Folder proyek yang disimpan di GitHub |
| Clone | Mengunduh salinan repositori ke komputer |
| Pull | Mengambil perubahan terbaru dari GitHub |
| Commit | Satu catatan perubahan kode, seperti "simpan" dengan keterangan |
| Push | Mengirim commit dari komputer ke GitHub |
| Branch | Cabang kerja terpisah untuk mengerjakan fitur tanpa mengganggu versi utama |
| Pull request (PR) | Pengajuan agar perubahan di sebuah branch digabung ke versi utama |
| Issue | Catatan tugas, ide, atau laporan bug |
| Milestone | Kumpulan issue untuk satu target waktu |
| Release | Versi aplikasi yang diberi nomor dan siap dicoba |
| APK | File pemasangan aplikasi Android |
| Emulator | HP tiruan yang berjalan di komputer |
| Terminal | Jendela untuk mengetik perintah |
| Tes otomatis | Program kecil yang memeriksa apakah fitur berjalan sesuai harapan |
| Data contoh | Data buatan untuk mencoba aplikasi, bukan data sungguhan |
| Wireflow | Rancangan layar yang bisa diklik, untuk menunjukkan alur aplikasi |
| PRD | Dokumen kebutuhan produk: apa yang dibuat, untuk siapa, dan aturannya |
| Flutter | Alat untuk membuat aplikasi Android dan iOS dari satu kode |
| Laravel | Alat untuk membuat server (API) |
| API | Jalur yang dipakai aplikasi HP untuk mengambil dan menyimpan data di server |
| SDK | Kumpulan alat yang dibutuhkan untuk membangun aplikasi |
