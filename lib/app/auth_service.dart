import 'api/api_client.dart';
import 'session.dart';

/// Akun yang berhasil masuk.
class SignedIn {
  const SignedIn({
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    this.address = '',
    this.user,
  });

  final UserRole role;
  final String name;
  final String email;
  final String phone;
  final String address;

  /// JSON akun dari server; null di mode demo.
  final Map<String, dynamic>? user;
}

/// Galat akun dengan pesan siap tampil.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Masuk, daftar, dan lupa kata sandi (FR-A2 sampai FR-A5).
abstract class AuthService {
  /// True jika memakai server sungguhan.
  bool get isRemote;

  Future<SignedIn> login(String id, String password);

  Future<SignedIn> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  });

  /// Minta kode verifikasi. Mengembalikan kode jika server dalam mode debug
  /// (atau mode demo), supaya bisa dicoba tanpa email/SMS.
  Future<String?> requestReset(String id);

  Future<void> resetPassword(String id, String code, String password);

  Future<void> logout();
}

UserRole? roleFromApi(Object? v) => switch (v) {
  'customer' => UserRole.customer,
  'partner' => UserRole.partner,
  'admin' => UserRole.admin,
  _ => null,
};

/// Memakai API Laravel.
class ApiAuthService implements AuthService {
  ApiAuthService(this.api);

  final ApiClient api;

  @override
  bool get isRemote => true;

  @override
  Future<SignedIn> login(String id, String password) => _signIn(
    () => api.post('/auth/login', {
      'login': id.trim(),
      'password': password,
      'device_name': 'sirkula-app',
    }),
  );

  @override
  Future<SignedIn> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) => _signIn(
    () => api.post('/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'password': password,
      'device_name': 'sirkula-app',
    }),
  );

  /// Pulihkan sesi dari token tersimpan. Mengembalikan null jika token tidak
  /// berlaku lagi.
  Future<SignedIn?> restore(String token) async {
    api.token = token;
    try {
      final json = await api.get('/auth/me');
      final user = Map<String, dynamic>.from(
        (json is Map && json['data'] is Map ? json['data'] : json) as Map,
      );
      return _fromUser(user);
    } on ApiException catch (e) {
      if (e.status == 401) {
        api.token = null;
        return null;
      }
      rethrow;
    }
  }

  Future<SignedIn> _signIn(Future<dynamic> Function() call) async {
    final dynamic json;
    try {
      json = await call();
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
    api.token = json['token'] as String;
    return _fromUser(Map<String, dynamic>.from(json['user'] as Map));
  }

  SignedIn _fromUser(Map<String, dynamic> user) {
    final role = roleFromApi(user['role']);
    if (role == null) throw AuthException('Peran akun tidak dikenal.');
    return SignedIn(
      role: role,
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
      phone: user['phone'] as String? ?? '',
      address: user['address'] as String? ?? '',
      user: user,
    );
  }

  @override
  Future<String?> requestReset(String id) async {
    try {
      final json = await api.post('/auth/forgot-password', {
        'login': id.trim(),
      });
      return json is Map ? json['debug_code'] as String? : null;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> resetPassword(String id, String code, String password) async {
    try {
      await api.post('/auth/reset-password', {
        'login': id.trim(),
        'code': code.trim(),
        'password': password,
      });
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<void> logout() async {
    if (api.token == null) return;
    try {
      await api.post('/auth/logout');
    } on ApiException {
      // Token tetap dibuang di HP walaupun server tidak bisa dihubungi.
    }
    api.token = null;
  }
}

/// Akun contoh di memori (mode demo dan tes).
class DemoAuthService implements AuthService {
  const DemoAuthService();

  @override
  bool get isRemote => false;

  @override
  Future<SignedIn> login(String id, String password) async {
    if (isCompanyEmail(id)) {
      throw AuthException(
        'Peran Admin hanya tersedia saat aplikasi tersambung ke server.',
      );
    }
    final a = authenticate(id, password);
    if (a == null) {
      throw AuthException('Nomor ponsel/email atau kata sandi salah.');
    }
    return _of(a);
  }

  @override
  Future<SignedIn> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    final error = registerCustomer(
      name: name,
      email: email,
      phone: phone,
      address: address,
      password: password,
    );
    if (error != null) throw AuthException(error);
    return _of(findAccount(email)!);
  }

  @override
  Future<String?> requestReset(String id) async {
    if (isCompanyEmail(id)) {
      throw AuthException(
        'Akun staf perusahaan dipulihkan oleh admin Sirkula.',
      );
    }
    if (findAccount(id) == null) {
      throw AuthException('Akun dengan email/nomor ini tidak ditemukan.');
    }
    return demoResetCode;
  }

  @override
  Future<void> resetPassword(String id, String code, String password) async {
    final a = findAccount(id);
    if (a == null) throw AuthException('Akun tidak ditemukan.');
    if (code.trim() != demoResetCode) {
      throw AuthException('Kode verifikasi salah.');
    }
    resetAccountPassword(a, password);
  }

  @override
  Future<void> logout() async {}

  static SignedIn _of(DemoAccount a) => SignedIn(
    role: a.role,
    name: a.label,
    email: a.email,
    phone: a.phone,
    address: a.address,
  );
}
