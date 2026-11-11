import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengaturan sambungan ke server.
///
/// - `--dart-define=DEMO=true` menjalankan aplikasi dengan data contoh tanpa
///   server.
/// - `--dart-define=API_URL=http://192.168.1.10:8000/api` mengganti alamat
///   bawaan. Alamat juga bisa diubah dari halaman masuk dan tersimpan di HP.
class AppConfig {
  AppConfig._();

  static const demoMode = bool.fromEnvironment('DEMO');
  static const _apiUrlDefine = String.fromEnvironment('API_URL');

  /// Alamat bawaan: emulator Android memakai 10.0.2.2 untuk laptop.
  static String get defaultApiUrl {
    if (_apiUrlDefine.isNotEmpty) return _apiUrlDefine;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }
}

/// Menyimpan token sesi dan alamat server di HP.
class SessionStorage {
  SessionStorage(this._prefs);

  final SharedPreferences? _prefs;

  static const _tokenKey = 'sirkula.token';
  static const _urlKey = 'sirkula.api_url';

  static Future<SessionStorage> open() async {
    try {
      return SessionStorage(await SharedPreferences.getInstance());
    } catch (_) {
      return SessionStorage(null); // penyimpanan tidak tersedia
    }
  }

  String? get token => _prefs?.getString(_tokenKey);
  String get apiUrl => _prefs?.getString(_urlKey) ?? AppConfig.defaultApiUrl;

  Future<void> saveToken(String? token) async {
    if (token == null) {
      await _prefs?.remove(_tokenKey);
    } else {
      await _prefs?.setString(_tokenKey, token);
    }
  }

  Future<void> saveApiUrl(String url) async => _prefs?.setString(_urlKey, url);
}
