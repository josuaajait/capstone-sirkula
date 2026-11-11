import 'dart:async';

import 'package:flutter/material.dart';

import 'admin/admin_shell.dart';
import 'admin/admin_store.dart';
import 'app/api/api_client.dart';
import 'app/app_config.dart';
import 'app/auth_service.dart';
import 'app/login_page.dart';
import 'app/push_service.dart';
import 'app/session.dart';
import 'app/splash_page.dart';
import 'app/theme.dart';
import 'customer/customer_shell.dart';
import 'customer/data/customer_store.dart';
import 'customer/data/models.dart';
import 'partner/data/partner_store.dart';
import 'partner/partner_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final customerStore = CustomerStore();
  final partnerStore = PartnerStore(customerStore);

  if (AppConfig.demoMode) {
    runApp(
      SirkulaApp(customerStore: customerStore, partnerStore: partnerStore),
    );
    return;
  }

  final storage = await SessionStorage.open();
  final api = ApiClient(storage.apiUrl);
  final push = PushService();
  await push.init();
  runApp(
    SirkulaApp(
      customerStore: customerStore,
      partnerStore: partnerStore,
      adminStore: AdminStore(),
      api: api,
      auth: ApiAuthService(api),
      storage: storage,
      push: push,
    ),
  );
}

class SirkulaApp extends StatefulWidget {
  const SirkulaApp({
    super.key,
    required this.customerStore,
    required this.partnerStore,
    this.adminStore,
    this.api,
    this.auth = const DemoAuthService(),
    this.storage,
    this.push,
    this.initialRole,
  });

  final CustomerStore customerStore;
  final PartnerStore partnerStore;
  final AdminStore? adminStore;

  /// Klien API; null berarti mode demo tanpa server.
  final ApiClient? api;
  final AuthService auth;
  final SessionStorage? storage;

  /// Notifikasi bilah status; null di mode demo dan tes.
  final PushService? push;

  /// Lewati halaman masuk (dipakai di test).
  final UserRole? initialRole;

  @override
  State<SirkulaApp> createState() => _SirkulaAppState();
}

class _SirkulaAppState extends State<SirkulaApp> {
  late UserRole? _role = widget.initialRole;
  late final AdminStore _adminStore = widget.adminStore ?? AdminStore();

  /// True selama memulihkan sesi tersimpan (layar splash).
  bool _restoring = false;
  Timer? _poll;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    if (widget.api != null) {
      _lifecycle = AppLifecycleListener(onResume: _refreshQuietly);
      if (widget.storage?.token case final token?) _restore(token);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _restore(String token) async {
    final auth = widget.auth;
    if (auth is! ApiAuthService) return;
    setState(() => _restoring = true);
    try {
      final signed = await auth.restore(token);
      if (signed != null) {
        await _connect(signed);
      } else {
        await widget.storage?.saveToken(null);
      }
    } on ApiException {
      // Server tidak terjangkau: tampilkan halaman masuk.
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  /// Dipanggil halaman masuk setelah akun cocok. Galat diteruskan agar tampil
  /// di halaman masuk.
  Future<void> _onLogin(SignedIn signed) async {
    if (signed.user != null) {
      await _connect(signed);
      await widget.storage?.saveToken(widget.api?.token);
    } else if (signed.role == UserRole.customer) {
      widget.customerStore.signInAs(
        email: signed.email,
        name: signed.name,
        phone: signed.phone,
        address: signed.address,
      );
    }
    if (mounted) setState(() => _role = signed.role);
  }

  Future<void> _connect(SignedIn signed) async {
    final api = widget.api!;
    final user = signed.user!;
    switch (signed.role) {
      case UserRole.customer:
        await widget.customerStore.connect(api, user);
      case UserRole.partner:
        await widget.partnerStore.connect(api, user);
      case UserRole.admin:
        await _adminStore.connect(api, user);
    }
    _role = signed.role;
    _owner = '${signed.role.name}:${signed.email}';
    await _notifyPush();
    widget.push?.registerFcm(api);
    _poll?.cancel();
    // Muat ulang berkala agar perubahan dari peran lain ikut terlihat.
    _poll = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshQuietly(),
    );
  }

  Future<void> _refreshQuietly() async {
    try {
      switch (_role) {
        case UserRole.customer:
          await widget.customerStore.refresh();
        case UserRole.partner:
          await widget.partnerStore.refresh();
        case UserRole.admin:
          await _adminStore.refresh();
        case null:
          break;
      }
      await _notifyPush();
    } on ApiException {
      // Coba lagi di putaran berikutnya.
    }
  }

  /// Akun yang sedang masuk, untuk membedakan notifikasi antarakun.
  String? _owner;

  /// Tampilkan notifikasi baru dari server di bilah status HP.
  Future<void> _notifyPush() async {
    final push = widget.push;
    final owner = _owner;
    if (push == null || owner == null) return;
    final list = switch (_role) {
      UserRole.customer => widget.customerStore.notifications,
      UserRole.partner => widget.partnerStore.notifications,
      UserRole.admin => _adminStore.notifications,
      null => const <AppNotification>[],
    };
    await push.onNotifications(owner, list);
  }

  Future<void> _logout() async {
    _poll?.cancel();
    setState(() => _role = null);
    _owner = null;
    await widget.push?.unregister(widget.api);
    await widget.auth.logout();
    await widget.storage?.saveToken(null);
    widget.customerStore.disconnect();
    widget.partnerStore.disconnect();
    _adminStore.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final Widget home = _restoring
        ? const SplashPage()
        : switch (_role) {
            null => LoginPage(onLogin: _onLogin),
            UserRole.customer => const CustomerShell(),
            UserRole.partner => const PartnerShell(),
            UserRole.admin => const AdminShell(),
          };
    return AppServices(
      auth: widget.auth,
      api: widget.api,
      storage: widget.storage,
      child: AppSession(
        role: _role,
        onLogout: _logout,
        child: CustomerScope(
          store: widget.customerStore,
          child: PartnerScope(
            store: widget.partnerStore,
            child: AdminScope(
              store: _adminStore,
              child: MaterialApp(
                title: 'Sirkula',
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(),
                home: KeyedSubtree(
                  key: ValueKey((_role, _restoring)),
                  child: home,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
