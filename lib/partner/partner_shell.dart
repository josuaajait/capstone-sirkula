import 'package:flutter/material.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../customer/data/models.dart';
import '../customer/widgets/common.dart';
import 'data/partner_store.dart';
import 'pages/partner_history_page.dart';
import 'pages/partner_home_page.dart';
import 'pages/partner_profile_page.dart';
import 'pages/pickup_schedule_page.dart';
import 'pages/requests_page.dart';
import 'pages/weigh_page.dart';

enum PartnerTab {
  home(
    'Beranda Mitra',
    'Beranda',
    Icons.space_dashboard_outlined,
    Icons.space_dashboard_rounded,
  ),
  requests(
    'Permintaan Setoran',
    'Permintaan',
    Icons.inbox_outlined,
    Icons.inbox_rounded,
  ),
  schedule(
    'Jadwal Jemput',
    'Jadwal',
    Icons.local_shipping_outlined,
    Icons.local_shipping_rounded,
  ),
  weigh(
    'Catat Timbangan',
    'Timbang',
    Icons.scale_outlined,
    Icons.scale_rounded,
  ),
  history(
    'Riwayat Setoran',
    'Riwayat',
    Icons.history_rounded,
    Icons.history_rounded,
  );

  const PartnerTab(this.title, this.navLabel, this.icon, this.activeIcon);
  final String title;
  final String navLabel;
  final IconData icon;
  final IconData activeIcon;
}

/// Kerangka aplikasi mitra bank sampah: header, isi tab, navigasi bawah.
class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key});

  /// Pindah tab. [weigh] mengisi halaman Catat Timbangan dengan setoran itu.
  ///
  /// Bisa dipanggil dari halaman yang di-push di atas shell (misalnya detail
  /// setoran), karena shell yang aktif juga disimpan di [_active].
  static void goTo(BuildContext context, PartnerTab tab, {Deposit? weigh}) {
    final state =
        context.findAncestorStateOfType<_PartnerShellState>() ??
        _PartnerShellState._active;
    state?._goTo(tab, weigh);
  }

  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  static _PartnerShellState? _active;

  PartnerTab _tab = PartnerTab.home;
  Deposit? _weighRequest;
  int _weighKey = 0;

  @override
  void initState() {
    super.initState();
    _active = this;
  }

  @override
  void dispose() {
    if (identical(_active, this)) _active = null;
    super.dispose();
  }

  void _goTo(PartnerTab tab, Deposit? weigh) {
    if (!mounted) return;
    setState(() {
      _tab = tab;
      if (tab == PartnerTab.weigh) {
        _weighRequest = weigh;
        _weighKey++; // buat ulang formulir agar pilihan terpakai
      }
    });
  }

  Widget _page() {
    switch (_tab) {
      case PartnerTab.home:
        return const PartnerHomePage();
      case PartnerTab.requests:
        return const RequestsPage();
      case PartnerTab.schedule:
        return const PickupSchedulePage();
      case PartnerTab.weigh:
        return WeighPage(key: ValueKey(_weighKey), request: _weighRequest);
      case PartnerTab.history:
        return const PartnerHistoryPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = PartnerScope.of(context);
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
                    'Kelola setoran customer ${store.partner.name}.',
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
              label: 'Buka profil mitra',
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PartnerProfilePage()),
                ),
                child: InitialsTile(store.partner.initials, size: 38),
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
        requestCount: store.requests.length,
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
        onTap: () => _show(context),
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

  void _show(BuildContext context) {
    final store = PartnerScope.read(context);
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
                          formatStamp(n.time),
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
  const _BottomNav({
    required this.current,
    required this.requestCount,
    required this.onSelect,
  });

  final PartnerTab current;
  final int requestCount;
  final ValueChanged<PartnerTab> onSelect;

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
          onDestinationSelected: (i) => onSelect(PartnerTab.values[i]),
          destinations: [
            for (final tab in PartnerTab.values)
              NavigationDestination(
                icon: _badge(tab, Icon(tab.icon)),
                selectedIcon: _badge(tab, Icon(tab.activeIcon)),
                label: tab.navLabel,
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(PartnerTab tab, Widget icon) =>
      tab == PartnerTab.requests && requestCount > 0
      ? Badge(
          label: Text('$requestCount'),
          backgroundColor: AppColors.coral,
          child: icon,
        )
      : icon;
}
