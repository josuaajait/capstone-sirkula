# Panduan Menjalankan dan Memantau Sirkula

Panduan ini ditulis untuk orang yang **tidak terbiasa dengan pemrograman**. Ikuti langkahnya berurutan, dan jangan khawatir jika ada istilah yang asing: setiap langkah menjelaskan apa yang harus diklik atau diketik.

Repositori proyek: <https://github.com/josuaajait/capstone-sirkula>

---

## Daftar isi

1. [Kondisi aplikasi saat ini](#1-kondisi-aplikasi-saat-ini)
2. [Cara termudah: pasang APK di HP Android](#2-cara-termudah-pasang-apk-di-hp-android)
3. [Menjalankan dari kode sumber (Windows)](#3-menjalankan-dari-kode-sumber-windows)
4. [Memperbarui ke versi terbaru](#4-memperbarui-ke-versi-terbaru)
5. [Menjalankan backend dan panel admin (nanti)](#5-menjalankan-backend-dan-panel-admin-nanti)
6. [Masalah yang sering muncul](#6-masalah-yang-sering-muncul)
7. [Memantau progres lewat GitHub](#7-memantau-progres-lewat-github)
8. [Daftar istilah](#8-daftar-istilah)

---

## 1. Kondisi aplikasi saat ini

Sirkula terdiri dari tiga bagian (lihat [PRD](PRD-Sirkula.md) untuk detailnya):

| Bagian | Untuk siapa | Teknologi | Status |
| --- | --- | --- | --- |
| Aplikasi HP | Customer dan Mitra bank sampah | Flutter | Kerangka awal sudah dibuat, fitur sedang dikerjakan |
| API (server) | Dipakai aplikasi HP di belakang layar | Laravel | Belum dibuat |
| Panel admin web | Staf Perusahaan | Laravel | Belum dibuat |

Artinya, **saat ini yang bisa dijalankan baru aplikasi Flutter**, dan isinya masih tampilan contoh. Panduan bagian 5 akan berlaku setelah backend selesai dibuat.

Target rilis pertama: **sekitar 8 Desember 2026**.

---

## 2. Cara termudah: pasang APK di HP Android

Jika Anda hanya ingin **mencoba** aplikasinya, tidak perlu memasang apa pun di komputer. Pengembang akan mengunggah file pemasangan (APK) di halaman Releases GitHub.

1. Buka <https://github.com/josuaajait/capstone-sirkula/releases> di HP Android.
2. Pilih versi paling atas (paling baru).
3. Di bagian **Assets**, ketuk file yang berakhiran `.apk`, misalnya `sirkula-v0.1.0.apk`.
4. Setelah terunduh, buka file tersebut.
5. Jika muncul peringatan *"Pemasangan dari sumber tidak dikenal diblokir"*, ketuk **Setelan**, lalu izinkan browser Anda memasang aplikasi. Kembali dan ketuk **Pasang**.
6. Buka aplikasi **Sirkula** dari layar utama HP.

> Jika halaman Releases masih kosong, berarti belum ada versi yang dibagikan. Gunakan cara di bagian 3, atau minta pengembang mengunggah APK.

> Pengguna iPhone belum bisa memasang langsung. Aplikasi iOS hanya bisa dibangun di komputer Mac, atau dibagikan lewat TestFlight nanti.

---

## 3. Menjalankan dari kode sumber (Windows)

Cara ini diperlukan jika Anda ingin melihat **versi paling baru** yang belum dirilis, atau ikut mengembangkan. Pemasangan pertama memakan waktu sekitar 30–60 menit dan butuh ruang kosong sekitar 10 GB.

### 3.1 Pasang Git

Git dipakai untuk mengunduh kode dari GitHub.

1. Buka <https://git-scm.com/download/win>.
2. Unduh **64-bit Git for Windows Setup**, lalu jalankan.
3. Klik **Next** terus sampai **Install**, biarkan semua pilihan bawaan.

### 3.2 Pasang Visual Studio Code

VS Code adalah aplikasi untuk membuka kode dan menjalankan perintah.

1. Buka <https://code.visualstudio.com/>, klik **Download for Windows**, lalu pasang.
2. Buka VS Code. Klik ikon kotak-kotak di sisi kiri (**Extensions**), atau tekan `Ctrl+Shift+X`.
3. Cari **Flutter**, lalu klik **Install** pada ekstensi buatan *Dart Code*. Ekstensi Dart ikut terpasang otomatis.

### 3.3 Pasang Flutter SDK

1. Di VS Code, tekan `Ctrl+Shift+P`, ketik **Flutter: New Project**, lalu tekan Enter.
2. Muncul tawaran mengunduh Flutter SDK. Klik **Download SDK**.
3. Pilih folder tanpa spasi, misalnya `C:\dev`. **Jangan** pilih `C:\Program Files`.
4. Tunggu sampai selesai (bisa 5–15 menit). Saat ditanya apakah ingin menambahkan Flutter ke PATH, klik **Add SDK to PATH**.
5. Tutup lalu buka kembali VS Code. Batalkan pembuatan proyek baru jika masih terbuka.

Cara lain: ikuti panduan resmi di <https://docs.flutter.dev/get-started/install/windows>.

### 3.4 Pilih tempat aplikasi akan tampil

Pilih **salah satu**. Pilihan A paling mudah.

**A. Di browser Chrome (paling mudah)**

Cukup pasang Google Chrome dari <https://www.google.com/chrome/>. Aplikasi akan tampil di jendela browser, mirip tampilan HP.

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

### 3.5 Periksa pemasangan

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

### 3.6 Unduh kode Sirkula

Di terminal VS Code, jalankan perintah ini satu per satu:

```bash
cd C:\dev
```

```bash
git clone https://github.com/josuaajait/capstone-sirkula.git
```

Jika repositori bersifat privat, akan muncul jendela masuk GitHub. Masuk dengan akun yang sudah diundang oleh pengembang (lihat bagian 7.1).

Setelah selesai, buka foldernya di VS Code lewat menu **File → Open Folder**, lalu pilih `C:\dev\capstone-sirkula`. Jika muncul pertanyaan *"Do you trust the authors?"*, klik **Yes, I trust the authors**.

### 3.7 Jalankan aplikasi

1. Buka terminal baru (**Terminal → New Terminal**). Pastikan terminal sudah berada di folder `capstone-sirkula`.
2. Unduh pustaka yang dibutuhkan aplikasi:

   ```bash
   flutter pub get
   ```

3. Jalankan aplikasi sesuai pilihan di langkah 3.4:

   | Pilihan | Perintah |
   | --- | --- |
   | A. Chrome | `flutter run -d chrome` |
   | B/C. HP atau emulator | `flutter run` |

   Untuk melihat daftar perangkat yang terdeteksi, jalankan `flutter devices`.

4. Pertama kali dijalankan, prosesnya bisa memakan 2–10 menit. Setelah itu aplikasi akan muncul.

Saat aplikasi berjalan, Anda bisa menekan tombol berikut di terminal:

| Tombol | Fungsi |
| --- | --- |
| `r` | Muat ulang cepat setelah kode berubah |
| `R` | Mulai ulang aplikasi dari awal |
| `q` | Hentikan aplikasi |

### 3.8 Membuat file APK sendiri (opsional)

Untuk membagikan aplikasi ke HP lain tanpa kabel:

```bash
flutter build apk --release
```

File hasilnya ada di `build\app\outputs\flutter-apk\app-release.apk`. Kirim file ini ke HP, lalu pasang seperti di bagian 2.

---

## 4. Memperbarui ke versi terbaru

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

## 5. Menjalankan backend dan panel admin (nanti)

> Bagian ini **belum bisa dijalankan**, karena API dan panel admin Laravel belum dibuat. Langkah di bawah adalah gambaran umum dan akan diperbarui setelah bagian tersebut ada di repositori.

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
6. Jalankan server: `php artisan serve`, lalu buka panel admin di `http://localhost:8000/admin`.
7. Arahkan aplikasi Flutter ke alamat server tersebut sesuai petunjuk di README nanti.

---

## 6. Masalah yang sering muncul

| Pesan atau gejala | Penyebab | Solusi |
| --- | --- | --- |
| `'flutter' is not recognized` | Flutter belum masuk PATH | Tutup semua jendela VS Code dan terminal, lalu buka lagi. Jika masih gagal, ulangi langkah 3.3 |
| `'git' is not recognized` | Git belum terpasang | Ulangi langkah 3.1, lalu buka ulang VS Code |
| `No devices found` | Tidak ada HP, emulator, atau Chrome | Nyalakan emulator, sambungkan HP, atau gunakan `flutter run -d chrome` |
| HP tidak muncul di `flutter devices` | USB debugging belum aktif atau belum diizinkan | Ulangi langkah 3.4 B, coba kabel lain, dan pilih mode **Transfer file** di HP |
| `Android license status unknown` | Lisensi belum diterima | Jalankan `flutter doctor --android-licenses` |
| Muncul error `pub get failed` | Koneksi internet bermasalah | Periksa internet, lalu ulangi `flutter pub get` |
| `Building with plugins requires symlink support` | Mode pengembang Windows belum aktif | Buka **Settings → System → For developers**, aktifkan **Developer Mode** |
| Proses `flutter run` sangat lama | Normal saat pertama kali | Tunggu sampai selesai. Jalankan berikutnya akan jauh lebih cepat |
| Ada error aneh setelah `git pull` | Sisa hasil build lama | Jalankan `flutter clean`, lalu `flutter pub get`, dan coba lagi |

Jika masih gagal, salin seluruh pesan error di terminal, lalu kirimkan ke pengembang atau buat Issue di GitHub (lihat bagian 7.4).

---

## 7. Memantau progres lewat GitHub

GitHub adalah tempat kode Sirkula disimpan. Dari sana Anda bisa melihat apa saja yang sudah dikerjakan, apa yang sedang dikerjakan, dan apa yang belum, **tanpa perlu menjalankan aplikasi**.

### 7.1 Siapkan akun

1. Daftar akun gratis di <https://github.com/signup>.
2. Kirim nama pengguna GitHub Anda ke pengembang.
3. Jika repositori privat, pengembang akan mengundang Anda sebagai *collaborator*. Buka email undangan dari GitHub, lalu klik **Accept invitation**.
4. Buka <https://github.com/josuaajait/capstone-sirkula>.

### 7.2 Nyalakan notifikasi

Agar mendapat kabar setiap ada perubahan:

1. Di halaman repositori, klik tombol **Watch** di kanan atas.
2. Pilih **All Activity** untuk semua kabar, atau **Custom → Issues, Pull requests, Releases** untuk kabar penting saja.
3. Kabar akan dikirim ke email Anda dan tampil di ikon lonceng 🔔 GitHub.

Pasang juga aplikasi **GitHub** untuk Android atau iOS agar bisa memantau dari HP.

### 7.3 Peta halaman repositori

| Tab | Yang bisa dilihat | Pertanyaan yang dijawab |
| --- | --- | --- |
| **Code** | File proyek dan README | Apa isi proyek ini? |
| **Commits** (klik tulisan *"N commits"* di tab Code) | Riwayat perubahan, lengkap dengan tanggal dan penjelasan | Apa yang dikerjakan hari ini atau minggu ini? |
| **Issues** | Daftar tugas, fitur, dan laporan bug | Apa saja yang belum selesai? |
| **Pull requests** | Perubahan yang sedang diajukan dan menunggu diperiksa | Fitur apa yang hampir jadi? |
| **Projects** | Papan tugas berkolom *Todo → In Progress → Done* | Bagaimana gambaran progres secara keseluruhan? |
| **Milestones** (di dalam tab Issues) | Kelompok tugas untuk satu target, dengan persentase selesai | Seberapa dekat dengan rilis 8 Desember? |
| **Actions** | Hasil pemeriksaan otomatis setiap ada perubahan | Apakah kode terbaru berjalan tanpa error? |
| **Releases** (di sisi kanan tab Code) | Versi aplikasi yang siap dicoba, beserta file APK | Versi mana yang bisa saya pasang? |
| **Insights → Pulse / Contributors** | Ringkasan aktivitas per minggu dan per orang | Seberapa aktif proyek ini? |

### 7.4 Cara membaca dan memakai setiap bagian

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

### 7.5 Ritme pemantauan yang disarankan

| Kapan | Yang dicek |
| --- | --- |
| Setiap hari, 2 menit | Email notifikasi GitHub, atau ikon lonceng |
| Setiap minggu | Papan **Projects** dan persentase **Milestone**, bandingkan dengan minggu lalu |
| Setiap ada rilis | Unduh APK dari **Releases**, coba aplikasinya, lalu laporkan temuan di **Issues** |

### 7.6 Catatan untuk pengembang

Agar pemantauan di atas berjalan, siapkan hal berikut di repositori:

- [ ] Buat milestone **Rilis 1 – 8 Des 2026** dan hubungkan ke setiap issue fitur Wajib.
- [ ] Buat satu issue per kebutuhan di PRD, dengan ID pada judul, misalnya `FR-C3 Pilih jenis sampah dan estimasi poin`.
- [ ] Buat label `customer`, `mitra`, `perusahaan`, `backend`, `bug`, dan `wajib`/`berikutnya`.
- [ ] Buat papan **Projects** dengan kolom Todo, In Progress, Review, dan Done.
- [ ] Tulis pesan commit yang jelas, dan sebut nomor issue, misalnya `Tambah layar pilih bank sampah (#12)`.
- [ ] Tambahkan GitHub Actions yang menjalankan `flutter analyze` dan `flutter test` di setiap perubahan.
- [ ] Unggah APK ke **Releases** setiap selesai satu tahap, misalnya setiap minggu.
- [ ] Undang pemantau sebagai collaborator jika repositori privat.

---

## 8. Daftar istilah

| Istilah | Arti sederhana |
| --- | --- |
| Repositori (repo) | Folder proyek yang disimpan di GitHub |
| Clone | Mengunduh salinan repositori ke komputer |
| Pull | Mengambil perubahan terbaru dari GitHub |
| Commit | Satu catatan perubahan kode, seperti "simpan" dengan keterangan |
| Branch | Cabang kerja terpisah untuk mengerjakan fitur tanpa mengganggu versi utama |
| Pull request (PR) | Pengajuan agar perubahan di sebuah branch digabung ke versi utama |
| Issue | Catatan tugas, ide, atau laporan bug |
| Milestone | Kumpulan issue untuk satu target waktu |
| Release | Versi aplikasi yang diberi nomor dan siap dicoba |
| APK | File pemasangan aplikasi Android |
| Emulator | HP tiruan yang berjalan di komputer |
| Terminal | Jendela untuk mengetik perintah |
| Flutter | Alat untuk membuat aplikasi Android dan iOS dari satu kode |
| Laravel | Alat untuk membuat server (API) dan panel admin web |
| SDK | Kumpulan alat yang dibutuhkan untuk membangun aplikasi |
