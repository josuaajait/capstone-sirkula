import 'package:flutter/material.dart';

import '../app/format.dart';
import '../app/session.dart';
import '../app/theme.dart';
import '../customer/widgets/common.dart';
import 'admin_store.dart';
import 'pages/admin_deposits_page.dart';
import 'pages/admin_home_page.dart';
import 'pages/admin_manage_page.dart';
import 'pages/admin_redemptions_page.dart';

enum AdminTab {
  home('Beranda Admin', 'Beranda', Icons.insights_outlined, Icons.insights),
  deposits(
    'Pantau Setoran',
    'Setoran',
    Icons.receipt_long_outlined,
    Icons.receipt_long,
  ),
  redemptions(
    'Proses Penukaran',
    'Penukaran',
    Icons.redeem_outlined,
    Icons.redeem,
  ),
  manage('Kelola Data', 'Kelola', Icons.tune_outlined, Icons.tune);

  const AdminTab(this.title, this.navLabel, this.icon, this.activeIcon);
  final String title;
  final String navLabel;
  final IconData icon;
  final IconData activeIcon;
}

/// Kerangka peran Admin perusahaan (FR-P1 sampai FR-P8). Admin memakai
/// aplikasi HP yang sama; tidak ada panel web.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminTab _tab = AdminTab.home;

  Widget _page() => switch (_tab) {
    AdminTab.home => const AdminHomePage(),
    AdminTab.deposits => const AdminDepositsPage(),
    AdminTab.redemptions => const AdminRedemptionsPage(),
    AdminTab.manage => const AdminManagePage(),
  };

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final pending = store.pendingRedemptions
        .where((r) => r.redemption.status.name == 'processing')
        .length;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: AppColors.white,
                child: Image.asset(
                  'assets/images/sirkula-logo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tab.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Admin Sirkula · ${store.bankSampah?.name ?? 'BSI Ias Toba'}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => _showNotifications(context),
            icon: Badge(
              isLabelVisible: store.unreadNotifications > 0,
              backgroundColor: AppColors.coral,
              smallSize: 7,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 6),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.line),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(key: ValueKey(_tab), child: _page()),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.mint,
          surfaceTintColor: Colors.transparent,
          height: 66,
          selectedIndex: _tab.index,
          onDestinationSelected: (i) =>
              setState(() => _tab = AdminTab.values[i]),
          destinations: [
            for (final t in AdminTab.values)
              NavigationDestination(
                icon: _badge(t, pending, Icon(t.icon)),
                selectedIcon: _badge(t, pending, Icon(t.activeIcon)),
                label: t.navLabel,
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(AdminTab t, int pending, Widget icon) =>
      t == AdminTab.redemptions && pending > 0
      ? Badge(
          label: Text('$pending'),
          backgroundColor: AppColors.coral,
          child: icon,
        )
      : icon;

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) AppSession.logout(context);
  }

  void _showNotifications(BuildContext context) {
    final store = AdminScope.read(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (store.notifications.isEmpty)
              const Text(
                'Belum ada notifikasi.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            for (final n in store.notifications)
              AppCard(
                padding: const EdgeInsets.all(14),
                color: n.read ? AppColors.white : AppColors.mint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatStamp(n.time),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).whenComplete(store.markNotificationsRead);
  }
}
