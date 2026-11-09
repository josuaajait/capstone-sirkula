import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../customer/data/models.dart';
import '../../customer/widgets/common.dart';
import '../data/partner_store.dart';
import '../partner_shell.dart';
import '../widgets/partner_widgets.dart';

/// Beranda mitra (FR-M1): berat diterima dibanding target bulanan, jumlah
/// customer, jadwal jemput hari ini, dan aktivitas terbaru.
class PartnerHomePage extends StatelessWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = PartnerScope.of(context);
    final requests = store.requests;
    final today = store.todayPickups;
    final recent = store.deposits.take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        _HeroCard(store: store),
        const SizedBox(height: 16),
        _TargetCard(store: store),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            PartnerStatCard(
              icon: Icons.people_alt_outlined,
              label: 'Customer Bulan Ini',
              value: formatNumber(store.customersThisMonth),
              note: '${store.verifiedThisMonth.length} setoran ditimbang',
            ),
            PartnerStatCard(
              icon: Icons.toll_outlined,
              label: 'Poin Diberikan',
              value: formatNumber(store.pointsThisMonth),
              note: 'Dihitung otomatis oleh sistem',
            ),
            PartnerStatCard(
              icon: Icons.inbox_outlined,
              label: 'Permintaan Baru',
              value: formatNumber(requests.length),
              note: requests.isEmpty
                  ? 'Semua sudah ditangani'
                  : 'Perlu diterima atau ditolak',
            ),
            PartnerStatCard(
              icon: Icons.local_shipping_outlined,
              label: 'Jemput Hari Ini',
              value: formatNumber(today.length),
              note: today.isEmpty
                  ? 'Tidak ada jadwal'
                  : 'Mulai ${today.first.pickupSlot} WIB',
            ),
          ],
        ),
        if (requests.isNotEmpty) ...[
          const SizedBox(height: 16),
          _RequestBanner(count: requests.length, first: requests.first),
        ],
        const SizedBox(height: 16),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 8, 12),
                child: SectionTitle(
                  'Jadwal Jemput Hari Ini',
                  subtitle: formatDateLong(DateTime.now()),
                  action: TextButton(
                    onPressed: () =>
                        PartnerShell.goTo(context, PartnerTab.schedule),
                    child: const Text(
                      'Semua Jadwal',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              if (today.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Tidak ada penjemputan hari ini.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                )
              else
                for (final d in today) ...[
                  _TodayPickupRow(d),
                  if (d != today.last)
                    const Divider(height: 1, color: AppColors.line),
                ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 8, 12),
                child: SectionTitle(
                  'Aktivitas Terbaru',
                  subtitle: 'Setoran customer di ${store.partner.name}',
                  action: TextButton(
                    onPressed: () =>
                        PartnerShell.goTo(context, PartnerTab.history),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              for (final d in recent) ...[
                PartnerDepositTile(d),
                if (d != recent.last)
                  const Divider(height: 1, color: AppColors.line),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.store});
  final PartnerStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: 8,
            child: Transform.rotate(
              angle: 0.2,
              child: Icon(
                Icons.eco_outlined,
                size: 120,
                color: AppColors.lime.withValues(alpha: 0.15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pill(
                  '${store.partner.name.toUpperCase()} · ${store.partner.accepts.length} JENIS SAMPAH',
                  background: AppColors.lime.withValues(alpha: 0.15),
                  foreground: AppColors.lime,
                ),
                const SizedBox(height: 14),
                Text(
                  'Selamat datang, ${store.partner.name}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Terima permintaan customer, jemput dengan kendaraan sendiri, lalu catat hasil timbang. Poin dihitung otomatis oleh sistem.',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            PartnerShell.goTo(context, PartnerTab.weigh),
                        icon: const Icon(Icons.scale_rounded, size: 18),
                        label: const Text('Catat Timbangan'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.lime,
                          foregroundColor: AppColors.sidebar,
                          minimumSize: const Size.fromHeight(46),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            PartnerShell.goTo(context, PartnerTab.requests),
                        icon: const Icon(Icons.inbox_rounded, size: 18),
                        label: const Text('Permintaan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          backgroundColor: AppColors.white.withValues(
                            alpha: 0.1,
                          ),
                          side: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.15),
                          ),
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.store});
  final PartnerStore store;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final kg = store.kgThisMonth;
    final target = PartnerStore.monthlyTargetKg;
    final left = (target - kg).clamp(0.0, target);
    final progress = store.targetProgress;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final onTrack = progress >= now.day / daysInMonth;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Target Bulanan',
            subtitle: 'Periode ${formatDate(now).split(' ').skip(1).join(' ')}',
            action: Pill(
              progress >= 1
                  ? 'Tercapai'
                  : onTrack
                  ? 'Sesuai jalur'
                  : 'Perlu dikejar',
              background: onTrack ? AppColors.emeraldSoft : AppColors.amberSoft,
              foreground: onTrack ? AppColors.emeraldDeep : AppColors.amberDeep,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text.rich(
                    TextSpan(
                      text: formatKg(kg),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                      children: [
                        TextSpan(
                          text: '  / ${formatKg(target)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).floor()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.mint,
              color: AppColors.primary,
              semanticsLabel: 'Progres target bulanan',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              left <= 0
                  ? 'Target bulan ini sudah tercapai. Terima kasih!'
                  : 'Kumpulkan ${formatKg(left)} lagi untuk mencapai target ${formatKg(target)} bulan ini.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestBanner extends StatelessWidget {
  const _RequestBanner({required this.count, required this.first});
  final int count;
  final Deposit first;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.amberSoft,
      borderColor: AppColors.amberSoft,
      onTap: () => PartnerShell.goTo(context, PartnerTab.requests),
      child: Row(
        children: [
          const IconTile(
            Icons.notifications_active_outlined,
            size: 44,
            background: AppColors.white,
            foreground: AppColors.amberDeep,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count permintaan menunggu',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amberDeep,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Terlama: ${first.customer.name} · ${first.type.label}, ${first.method.label.toLowerCase()}',
                  style: const TextStyle(fontSize: 12, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.amberDeep),
        ],
      ),
    );
  }
}

class _TodayPickupRow extends StatelessWidget {
  const _TodayPickupRow(this.d);
  final Deposit d;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openPartnerDeposit(context, d),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                d.pickupSlot?.split('–').first ?? '-',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${d.customer.name} · ${d.type.label} ±${formatKg(d.estimatedKg)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    d.address ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.subtle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusPill.deposit(d.status),
          ],
        ),
      ),
    );
  }
}
