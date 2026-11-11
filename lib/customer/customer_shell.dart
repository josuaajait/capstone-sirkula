import 'package:flutter/material.dart';

import '../app/format.dart';
import '../app/theme.dart';
import 'data/customer_store.dart';
import 'data/models.dart';
import 'pages/deposit_page.dart';
import 'pages/history_page.dart';
import 'pages/home_page.dart';
import 'pages/pickup_page.dart';
import 'pages/profile_page.dart';
import 'pages/rewards_page.dart';
import 'widgets/common.dart';

enum CustomerTab {
  home('Beranda', 'Beranda', Icons.home_outlined, Icons.home_rounded),
  deposit(
    'Setor Sampah',
    'Setor',
    Icons.move_to_inbox_outlined,
    Icons.move_to_inbox_rounded,
  ),
  pickup(
    'Penjemputan',
    'Jemput',
    Icons.local_shipping_outlined,
    Icons.local_shipping_rounded,
  ),
  rewards(
    'Poin & Hadiah',
    'Hadiah',
    Icons.card_giftcard_outlined,
    Icons.card_giftcard_rounded,
  ),
  history('Riwayat', 'Riwayat', Icons.history_rounded, Icons.history_rounded);

  const CustomerTab(this.title, this.navLabel, this.icon, this.activeIcon);
  final String title;
  final String navLabel;
  final IconData icon;
  final IconData activeIcon;
}

/// Pilihan awal untuk halaman Setor Sampah saat dibuka dari halaman lain.
class DepositPreset {
  const DepositPreset({this.method});
  final DepositMethod? method;
}

/// Kerangka aplikasi customer: header, isi tab, dan navigasi bawah.
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  /// Pindah tab dari halaman mana pun di dalam shell.
  static void goTo(
    BuildContext context,
    CustomerTab tab, {
    DepositPreset? preset,
  }) {
    context.findAncestorStateOfType<_CustomerShellState>()!._goTo(tab, preset);
  }

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  CustomerTab _tab = CustomerTab.home;
  DepositPreset? _preset;
  int _depositKey = 0;

  void _goTo(CustomerTab tab, DepositPreset? preset) {
    setState(() {
      _tab = tab;
      if (preset != null) {
        _preset = preset;
        _depositKey++; // buat ulang formulir agar preset terpakai
      }
    });
  }

  Widget _page() {
    switch (_tab) {
      case CustomerTab.home:
        return const CustomerHomePage();
      case CustomerTab.deposit:
        return DepositPage(key: ValueKey(_depositKey), preset: _preset);
      case CustomerTab.pickup:
        return const PickupPage();
      case CustomerTab.rewards:
        return const RewardsPage();
      case CustomerTab.history:
        return const HistoryPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = CustomerScope.of(context);
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
                    'Kelola sampah dan poin ${store.profile.name}.',
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
          _NotificationButton(count: store.unreadNotifications),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Semantics(
              button: true,
              label: 'Buka profil',
              child: GestureDetector(
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
                child: InitialsTile(store.profile.initials, size: 38),
              ),
            ),
          ),
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
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onSelect: (tab) => _goTo(tab, null),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notifikasi, $count belum dibaca',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showNotifications(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: AppColors.muted,
              ),
              if (count > 0)
                const Positioned(
                  right: 10,
                  top: 9,
                  child: CircleAvatar(
                    radius: 3.5,
                    backgroundColor: AppColors.coral,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final store = CustomerScope.read(context);
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
            for (final n in store.notifications)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: n.read ? AppColors.white : AppColors.mint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          formatDateShort(n.time),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.subtle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.4,
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

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onSelect});

  final CustomerTab current;
  final ValueChanged<CustomerTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.mint,
        surfaceTintColor: Colors.transparent,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.subtle,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.subtle,
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: current.index,
          onDestinationSelected: (i) => onSelect(CustomerTab.values[i]),
          destinations: [
            for (final tab in CustomerTab.values)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.navLabel,
              ),
          ],
        ),
      ),
    );
  }
}
