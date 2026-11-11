import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../customer_shell.dart';
import '../data/customer_store.dart';
import '../data/models.dart';
import '../widgets/activity_tile.dart';
import '../widgets/common.dart';
import '../widgets/deposit_chart.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CustomerScope.of(context);
    final nextPickup = store.activePickups.isEmpty
        ? null
        : store.activePickups.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        _HeroCard(name: store.profile.name, tier: store.profile.tier),
        const SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Tinggi tetap agar tidak terpotong di layar sempit (360 px).
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 156,
          ),
          children: [
            _StatCard(
              icon: Icons.toll_outlined,
              label: 'Saldo Poin',
              value: formatNumber(store.points),
              note: 'Poin tidak pernah hangus',
            ),
            _StatCard(
              icon: Icons.scale_outlined,
              label: 'Total Setoran',
              value: formatKg(store.totalVerifiedKg),
              note: 'Sejak bergabung',
            ),
            _StatCard(
              icon: Icons.local_shipping_outlined,
              label: 'Jemput Berikutnya',
              value: nextPickup?.pickupDate == null
                  ? '—'
                  : formatDateShort(nextPickup!.pickupDate!),
              note: nextPickup?.pickupSlot == null
                  ? 'Belum ada jadwal'
                  : '${nextPickup!.pickupSlot} WIB',
            ),
            _StatCard(
              icon: Icons.eco_outlined,
              label: 'Dampak Anda',
              value: formatKg(store.co2AvoidedKg),
              note: 'CO₂e berhasil dihindari',
            ),
          ],
        ),
        if (nextPickup != null) ...[
          const SizedBox(height: 16),
          _PickupStatusCard(deposit: nextPickup),
        ],
        const SizedBox(height: 16),
        DepositChart(deposits: store.deposits),
        const SizedBox(height: 16),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 8, 12),
                child: SectionTitle(
                  'Aktivitas Terbaru',
                  subtitle: 'Transaksi Anda di berbagai mitra',
                  action: TextButton(
                    onPressed: () =>
                        CustomerShell.goTo(context, CustomerTab.history),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              for (final a in store.activities.take(3)) ...[
                ActivityTile(a),
                if (a != store.activities.take(3).last)
                  const Divider(height: 1, color: AppColors.line),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _BankSampahCard(partner: CustomerStore.bankSampah),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.name, required this.tier});
  final String name;
  final String tier;

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
                  tier.toUpperCase(),
                  background: AppColors.lime.withValues(alpha: 0.15),
                  foreground: AppColors.lime,
                ),
                const SizedBox(height: 14),
                Text(
                  'Halo, $name',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Setor sampah terpilah ke BSI Ias Toba. Diterima Plastik, Kertas, Kaleng, dan Kaca.',
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
                            CustomerShell.goTo(context, CustomerTab.deposit),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const FittedBox(
                          child: Text('Setor Sampah', maxLines: 1),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.lime,
                          foregroundColor: AppColors.sidebar,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            CustomerShell.goTo(context, CustomerTab.rewards),
                        icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                        label: const FittedBox(
                          child: Text('Tukar Poin', maxLines: 1),
                        ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon, size: 36),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: AppColors.subtle),
          ),
        ],
      ),
    );
  }
}

class _PickupStatusCard extends StatelessWidget {
  const _PickupStatusCard({required this.deposit});
  final Deposit deposit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => CustomerShell.goTo(context, CustomerTab.pickup),
      child: Row(
        children: [
          const IconTile(Icons.local_shipping_outlined, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATUS JEMPUT',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${deposit.partner.name} · ${deposit.type.label} ${formatKg(deposit.estimatedKg)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                StatusPill.deposit(deposit.status),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.subtle),
        ],
      ),
    );
  }
}

class _BankSampahCard extends StatelessWidget {
  const _BankSampahCard({required this.partner});
  final Partner partner;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'Bank Sampah Sirkula',
            subtitle: 'Tempat semua setoran Anda ditimbang',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                InitialsTile(partner.initials, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Menerima plastik, kertas, kaleng, dan kaca',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _IconText(
            Icons.location_on_outlined,
            '${partner.address}, ${partner.area}',
          ),
          const SizedBox(height: 8),
          _IconText(Icons.calendar_today_outlined, partner.hours),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => CustomerShell.goTo(
              context,
              CustomerTab.deposit,
              preset: const DepositPreset(method: DepositMethod.dropOff),
            ),
            child: const Text('Setor ke Bank Sampah'),
          ),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}
