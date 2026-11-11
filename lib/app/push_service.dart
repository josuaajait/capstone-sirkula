import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../customer/data/models.dart';
import 'api/api_client.dart';
import 'app_config.dart';

/// Notifikasi di bilah status HP.
///
/// Ada dua jalur:
/// - **Lokal** (bawaan): setiap kali data dimuat ulang dari server, notifikasi
///   baru yang belum dibaca ditampilkan di bilah status. Berjalan selama
///   aplikasi terbuka atau masih hidup di latar belakang.
/// - **FCM** (`--dart-define=FCM=true`, butuh proyek Firebase): server
///   mengirim push lewat Firebase, jadi notifikasi muncul walaupun aplikasi
///   tertutup. Saat FCM aktif, jalur lokal dimatikan agar tidak dobel.
class PushService {
  PushService({
    FlutterLocalNotificationsPlugin? plugin,
    @visibleForTesting this.display,
  }) : _local = plugin ?? FlutterLocalNotificationsPlugin(),
       _ready = display != null;

  /// Pengganti tampilan untuk tes.
  final Future<void> Function(int id, String title, String body)? display;

  final FlutterLocalNotificationsPlugin _local;

  static const _channel = AndroidNotificationChannel(
    'sirkula',
    'Sirkula',
    description: 'Setoran, poin, dan penukaran hadiah',
    importance: Importance.high,
  );

  bool _ready;
  bool _fcmActive = false;
  String? _fcmToken;
  StreamSubscription<RemoteMessage>? _onMessage;
  StreamSubscription<String>? _onTokenRefresh;

  /// Notifikasi yang sudah pernah dilihat, per akun.
  String? _owner;
  final Set<int> _seen = {};

  /// Siapkan plugin. Di peramban tidak ada notifikasi bilah status.
  Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      final android = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_channel);
      await android?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Notifikasi lokal tidak tersedia: $e');
    }
  }

  /// Dipanggil setelah data dimuat ulang. Saat pertama untuk sebuah akun,
  /// semua notifikasi yang ada dianggap sudah dilihat; setelah itu hanya yang
  /// baru dan belum dibaca yang ditampilkan.
  Future<void> onNotifications(String owner, List<AppNotification> list) async {
    if (_owner != owner) {
      _owner = owner;
      _seen
        ..clear()
        ..addAll(list.map((n) => n.id).whereType<int>());
      return;
    }
    final fresh = [
      for (final n in list)
        if (n.id != null && !n.read && _seen.add(n.id!)) n,
    ];
    if (!_ready || _fcmActive) return;
    // Paling banyak 3 sekaligus agar bilah status tidak penuh.
    for (final n in fresh.take(3)) {
      await show(n.id!, n.title, n.body);
    }
  }

  Future<void> show(int id, String title, String body) async {
    if (!_ready) return;
    if (display != null) return display!(id, title, body);
    await _local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Daftarkan HP ini ke server untuk push FCM. Tidak melakukan apa-apa jika
  /// FCM belum diaktifkan atau Firebase belum diatur.
  Future<void> registerFcm(ApiClient api) async {
    if (!AppConfig.fcmEnabled || kIsWeb) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null) return;
      _fcmToken = token;
      final json = await api.post('/devices', {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      });
      // Server belum punya kunci Firebase: tetap pakai notifikasi lokal.
      _fcmActive = json is Map && json['push_enabled'] == true;

      // Saat aplikasi terbuka, FCM tidak menampilkan apa-apa sendiri.
      await _onMessage?.cancel();
      _onMessage = FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n == null) return;
        final id = int.tryParse('${m.data['notification_id']}');
        if (id != null) _seen.add(id);
        show(id ?? m.hashCode, n.title ?? 'Sirkula', n.body ?? '');
      });
      await _onTokenRefresh?.cancel();
      _onTokenRefresh = messaging.onTokenRefresh.listen((t) {
        _fcmToken = t;
        api.post('/devices', {'token': t}).catchError((_) => null);
      });
    } catch (e) {
      // Biasanya karena google-services.json belum dipasang.
      debugPrint('FCM tidak aktif: $e');
      _fcmActive = false;
    }
  }

  /// Dipanggil saat keluar akun, sebelum token API dibuang.
  Future<void> unregister(ApiClient? api) async {
    final token = _fcmToken;
    _owner = null;
    _seen.clear();
    _fcmActive = false;
    _fcmToken = null;
    await _onMessage?.cancel();
    await _onTokenRefresh?.cancel();
    if (token != null && api?.token != null) {
      try {
        await api!.delete('/devices', {'token': token});
      } on ApiException {
        // Server tidak terjangkau: token lama dibersihkan server nanti.
      }
    }
  }
}
