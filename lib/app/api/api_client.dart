import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Galat dari server atau jaringan, dengan pesan yang siap ditampilkan.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.status,
    this.reason,
    this.errors = const {},
  });

  final String message;

  /// Kode status HTTP; null jika server tidak bisa dihubungi.
  final int? status;

  /// Kode aturan bisnis dari server, misalnya `insufficient_points`.
  final String? reason;

  /// Galat validasi per kolom (status 422).
  final Map<String, List<String>> errors;

  bool get isNetwork => status == null;

  @override
  String toString() => message;
}

/// Klien HTTP sederhana untuk API Laravel Sirkula. Token Sanctum dikirim di
/// header `Authorization` setelah masuk.
class ApiClient {
  ApiClient(String baseUrl, {http.Client? client, this.token})
    : _baseUrl = _clean(baseUrl),
      _http = client ?? http.Client();

  String _baseUrl;

  /// Alamat API, misalnya `http://192.168.1.10:8000/api`.
  String get baseUrl => _baseUrl;
  set baseUrl(String v) => _baseUrl = _clean(v);

  static String _clean(String v) {
    var s = v.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'http://$s';
    return s;
  }

  final http.Client _http;
  String? token;

  static const _timeout = Duration(seconds: 20);

  Future<dynamic> get(String path, [Map<String, String?>? query]) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path, [Map<String, dynamic>? body]) =>
      _send('DELETE', path, body: body);

  /// Unggah satu file (multipart/form-data), misalnya foto timbangan.
  Future<dynamic> upload(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
  }) {
    final request = http.MultipartRequest('POST', uri(path))
      ..files.add(
        http.MultipartFile.fromBytes(field, bytes, filename: filename),
      );
    return _dispatch(request, timeout: const Duration(seconds: 60));
  }

  Uri uri(String path, [Map<String, String?>? query]) {
    final q = {
      for (final e in (query ?? const <String, String?>{}).entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    return Uri.parse('$baseUrl$path')
        .replace(queryParameters: q.isEmpty ? null : q);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String?>? query,
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, uri(path, query));
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    return _dispatch(request);
  }

  Future<dynamic> _dispatch(
    http.BaseRequest request, {
    Duration timeout = _timeout,
  }) async {
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(timeout),
      );
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Coba lagi sebentar lagi.');
    } catch (_) {
      throw ApiException(
        'Tidak bisa terhubung ke server. Periksa koneksi internet dan alamat server.',
      );
    }

    final text = utf8.decode(response.bodyBytes);
    dynamic json;
    if (text.isNotEmpty) {
      try {
        json = jsonDecode(text);
      } on FormatException {
        json = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    throw _error(response.statusCode, json);
  }

  static ApiException _error(int status, dynamic json) {
    final map = json is Map ? json : const {};
    final errors = <String, List<String>>{};
    final raw = map['errors'];
    if (raw is Map) {
      raw.forEach((k, v) {
        errors['$k'] = [
          for (final m in (v is List ? v : [v])) '$m',
        ];
      });
    }
    // Pesan kolom pertama lebih jelas daripada ringkasan Laravel.
    final message = errors.values.isNotEmpty && errors.values.first.isNotEmpty
        ? errors.values.first.first
        : switch (status) {
            401 => 'Sesi berakhir. Silakan masuk lagi.',
            403 => map['message'] as String? ?? 'Akses ditolak.',
            404 => map['message'] as String? ?? 'Data tidak ditemukan.',
            429 => 'Terlalu banyak percobaan. Tunggu sebentar.',
            >= 500 => 'Terjadi galat di server. Coba lagi nanti.',
            _ => map['message'] as String? ?? 'Permintaan gagal ($status).',
          };
    return ApiException(
      message,
      status: status,
      reason: map['reason'] as String?,
      errors: errors,
    );
  }
}
