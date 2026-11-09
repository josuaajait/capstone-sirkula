import 'package:flutter/material.dart';

import 'app/login_page.dart';
import 'app/session.dart';
import 'app/theme.dart';
import 'customer/customer_shell.dart';
import 'customer/data/customer_store.dart';
import 'partner/data/partner_store.dart';
import 'partner/partner_shell.dart';

void main() {
  final customerStore = CustomerStore();
  runApp(
    SirkulaApp(
      customerStore: customerStore,
      partnerStore: PartnerStore(customerStore),
    ),
  );
}

class SirkulaApp extends StatefulWidget {
  const SirkulaApp({
    super.key,
    required this.customerStore,
    required this.partnerStore,
    this.initialRole,
  });

  final CustomerStore customerStore;
  final PartnerStore partnerStore;

  /// Lewati halaman masuk (dipakai di test).
  final UserRole? initialRole;

  @override
  State<SirkulaApp> createState() => _SirkulaAppState();
}

class _SirkulaAppState extends State<SirkulaApp> {
  late UserRole? _role = widget.initialRole;

  @override
  Widget build(BuildContext context) {
    final Widget home = switch (_role) {
      null => LoginPage(onLogin: (role) => setState(() => _role = role)),
      UserRole.customer => const CustomerShell(),
      UserRole.partner => const PartnerShell(),
    };
    return AppSession(
      role: _role,
      onLogout: () => setState(() => _role = null),
      child: CustomerScope(
        store: widget.customerStore,
        child: PartnerScope(
          store: widget.partnerStore,
          child: MaterialApp(
            title: 'Sirkula',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: KeyedSubtree(key: ValueKey(_role), child: home),
          ),
        ),
      ),
    );
  }
}
