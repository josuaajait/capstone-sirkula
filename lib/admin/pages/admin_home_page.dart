import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../customer/widgets/common.dart';
import '../../partner/widgets/partner_widgets.dart';
import '../admin_store.dart';

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Beranda admin (FR-P1): berat bulan ini dibanding target, emisi
/// terhindarkan, customer aktif, dan grafik enam bulan.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final s = store.summary;
    if (s == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () => runAction(context, store.refresh),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          PageHeading(
            'Halo, ${store.profile.name}',
            'Ringkasan ${store.bankSampah?.name ?? 'BSI Ias Toba'} bulan ini.',
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Target bulanan'),
                const SizedBox(height: 12),
                Text(
                  '${formatKg(s.kgThisMonth)} dari ${formatKg(s.targetKg)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: s.targetProgress.clamp(0, 1).toDouble(),
                    minHeight: 10,
                    backgroundColor: AppColors.mint,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(s.targetProgress * 100).round()}% tercapai',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
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
                icon: Icons.eco_outlined,
                label: 'Emisi Terhindarkan',
                value: '${formatDecimal(s.co2ThisMonthKg / 1000, 3)} tCO2e',
                note: '${formatKg(s.co2ThisMonthKg)} CO2e bulan ini',
              ),
              PartnerStatCard(
                icon: Icons.people_alt_outlined,
                label: 'Customer Aktif',
                value: formatNumber(s.activeCustomers),
                note: 'dari ${formatNumber(s.totalCustomers)} terdaftar',
              ),
              PartnerStatCard(
                icon: Icons.toll_outlined,
                label: 'Poin Diberikan',
                value: formatNumber(s.pointsThisMonth),
                note: 'Bulan ini',
              ),
              PartnerStatCard(
                icon: Icons.redeem_outlined,
                label: 'Penukaran Baru',
                value: formatNumber(s.pendingRedemptions),
                note: s.pendingRedemptions == 0
                    ? 'Semua sudah diproses'
                    : 'Menunggu dikirim',
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  'Berat ditimbang',
                  subtitle: 'Enam bulan terakhir',
                ),
                const SizedBox(height: 16),
                _BarChart(data: s.monthlyKg),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  'Per kelompok sampah',
                  subtitle: 'Bulan ini',
                ),
                const SizedBox(height: 8),
                if (s.kgByGroup.isEmpty)
                  const Text(
                    'Belum ada setoran ditimbang bulan ini.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                for (final (name, kg) in s.kgByGroup)
                  InfoRow(name, formatKg(kg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Format angka desimal Indonesia, misalnya 0,126.
String formatDecimal(double v, int digits) =>
    v.toStringAsFixed(digits).replaceAll('.', ',');

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data});

  final List<(DateTime, double)> data;

  @override
  Widget build(BuildContext context) {
    final max = data.fold<double>(0, (m, e) => e.$2 > m ? e.$2 : m);
    return Semantics(
      label:
          'Grafik berat: ${data.map((e) => '${_monthNames[e.$1.month - 1]} ${formatKg(e.$2)}').join(', ')}',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (month, kg) in data)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          child: Text(
                            kg == 0 ? '' : formatNumber(kg.round()),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: max == 0 ? 2 : 2 + 100 * kg / max,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _monthNames[month.month - 1],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.subtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
