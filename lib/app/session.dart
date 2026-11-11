import 'package:flutter/widgets.dart';

import 'api/api_client.dart';
import 'app_config.dart';
import 'auth_service.dart';

/// Peran yang bisa masuk ke aplikasi HP. Admin adalah staf perusahaan
/// Sirkula; perannya hanya tersedia saat tersambung ke server.
enum UserRole { customer, partner, admin }

/// Akun contoh untuk mode demo tanpa server. Peran terikat ke akun (FR-A3),
/// bukan dipilih bebas saat masuk.
class DemoAccount {
  const DemoAccount({
    required this.role,
    required this.label,
    required this.email,
    required this.phone,
    this.address = '',
  });

  final UserRole role;
  final String label;
  final String email;
  final String phone;

  /// Alamat penjemputan; hanya diisi untuk akun customer hasil daftar.
  final String address;

  /// Kata sandi contoh untuk semua akun demo.
  static const password = 'sirkula123';
}

const demoAccounts = [
  DemoAccount(
    role: UserRole.customer,
    label: 'Customer 1',
    email: 'customer1@example.com',
    phone: '081200000101',
  ),
  DemoAccount(
    role: UserRole.partner,
    label: 'BSI Ias Toba',
    email: 'mitra1@example.com',
    phone: '081200000001',
  ),
];

/// Email yang dikenali sebagai staf perusahaan (peran Admin).
bool isCompanyEmail(String input) =>
    input.trim().toLowerCase().endsWith('@sirkula.id');

// ---------- Registri akun (sementara, sampai API Laravel siap) ----------

final List<DemoAccount> _registered = [];
final Map<String, String> _passwords = {};

List<DemoAccount> get allAccounts => [...demoAccounts, ..._registered];

String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

/// Menyamakan 0812…, 62812…, dan +62 812… menjadi 0812….
String normalizePhone(String input) {
  final d = _digits(input);
  if (d.startsWith('62')) return '0${d.substring(2)}';
  return d;
}

/// Mencari akun dari email atau nomor ponsel.
DemoAccount? findAccount(String id) {
  final q = id.trim().toLowerCase();
  final phone = normalizePhone(q);
  for (final a in allAccounts) {
    if (q == a.email) return a;
    if (phone.length >= 9 && phone == normalizePhone(a.phone)) return a;
  }
  return null;
}

/// Mencocokkan email/nomor ponsel dan kata sandi ke akun yang terdaftar.
DemoAccount? authenticate(String id, String password) {
  final account = findAccount(id);
  if (account == null) return null;
  final expected = _passwords[account.email] ?? DemoAccount.password;
  return password == expected ? account : null;
}

/// Aturan kata sandi minimal: 8 karakter, ada huruf dan angka.
String? validatePassword(String? v) {
  if (v == null || v.length < 8) return 'Kata sandi minimal 8 karakter.';
  if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
    return 'Kata sandi harus berisi huruf dan angka.';
  }
  return null;
}

/// Daftar akun customer baru (FR-A4). Mitra didaftarkan perusahaan lewat
/// admin perusahaan (FR-P2), jadi tidak bisa daftar sendiri di sini.
/// Mengembalikan pesan galat jika gagal.
String? registerCustomer({
  required String name,
  required String email,
  required String phone,
  required String address,
  required String password,
}) {
  final e = email.trim().toLowerCase();
  if (isCompanyEmail(e)) {
    return 'Email @sirkula.id khusus staf perusahaan.';
  }
  if (findAccount(e) != null) return 'Email sudah terdaftar. Silakan masuk.';
  if (findAccount(phone) != null) {
    return 'Nomor ponsel sudah terdaftar. Silakan masuk.';
  }
  _registered.add(
    DemoAccount(
      role: UserRole.customer,
      label: name.trim(),
      email: e,
      phone: normalizePhone(phone),
      address: address.trim(),
    ),
  );
  _passwords[e] = password;
  return null;
}

/// Mengganti kata sandi setelah kode verifikasi benar (FR-A5).
void resetAccountPassword(DemoAccount account, String newPassword) {
  _passwords[account.email] = newPassword;
}

/// Kode verifikasi tiruan. Backend nanti mengirim kode sungguhan.
const demoResetCode = '123456';

/// Hanya untuk tes: kembalikan registri ke keadaan awal.
void resetAccountRegistry() {
  _registered.clear();
  _passwords.clear();
}

/// Memberi halaman akses ke aksi keluar akun.
class AppSession extends InheritedWidget {
  const AppSession({
    super.key,
    required this.role,
    required this.onLogout,
    required super.child,
  });

  final UserRole? role;
  final VoidCallback onLogout;

  static AppSession? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppSession>();

  static void logout(BuildContext context) => maybeOf(context)?.onLogout();

  @override
  bool updateShouldNotify(AppSession oldWidget) => role != oldWidget.role;
}

/// Layanan yang dipakai halaman akun: [AuthService], klien API, dan
/// penyimpanan sesi.
class AppServices extends InheritedWidget {
  const AppServices({
    super.key,
    required this.auth,
    this.api,
    this.storage,
    required super.child,
  });

  final AuthService auth;
  final ApiClient? api;
  final SessionStorage? storage;

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppServices>() ??
      const AppServices(auth: DemoAuthService(), child: SizedBox.shrink());

  @override
  bool updateShouldNotify(AppServices oldWidget) =>
      auth != oldWidget.auth || api != oldWidget.api;
}
