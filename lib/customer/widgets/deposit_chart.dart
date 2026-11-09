import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../data/models.dart';
import 'common.dart';

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

/// Grafik batang berat setoran terverifikasi per bulan, 6 bulan terakhir
/// (FR-C1).
class DepositChart extends StatelessWidget {
  const DepositChart({super.key, required this.deposits, this.now});

  final List<Deposit> deposits;

  /// Bisa diisi di tes agar hasilnya tetap.
  final DateTime? now;

  static const months = 6;

  /// Total kg per bulan, dari yang terlama ke bulan ini.
  static List<(DateTime, double)> monthlyKg(
    List<Deposit> deposits,
    DateTime now,
  ) {
    final result = <(DateTime, double)>[];
    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final kg = deposits
          .where(
            (d) =>
                d.status == DepositStatus.verified &&
                d.createdAt.year == month.year &&
                d.createdAt.month == month.month,
          )
          .fold(0.0, (sum, d) => sum + (d.weighedKg ?? 0));
      result.add((month, kg));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final data = monthlyKg(deposits, now ?? DateTime.now());
    final maxKg = data.fold(0.0, (m, e) => e.$2 > m ? e.$2 : m);
    final total = data.fold(0.0, (s, e) => s + e.$2);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Setoran 6 Bulan Terakhir',
            subtitle: 'Berat hasil timbang mitra per bulan',
            action: Pill(formatKg(total)),
          ),
          const SizedBox(height: 20),
          Semantics(
            label:
                'Grafik setoran: ${data.map((e) => '${_monthNames[e.$1.month - 1]} ${formatKg(e.$2)}').join(', ')}',
            excludeSemantics: true,
            child: SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < data.length; i++)
                    Expanded(
                      child: _Bar(
                        label: _monthNames[data[i].$1.month - 1],
                        kg: data[i].$2,
                        ratio: maxKg == 0 ? 0 : data[i].$2 / maxKg,
                        current: i == data.length - 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.kg,
    required this.ratio,
    required this.current,
  });

  final String label;
  final double kg;
  final double ratio;
  final bool current;

  @override
  Widget build(BuildContext context) {
    // Ruang untuk angka di atas batang dan label bulan di bawahnya.
    const maxBarHeight = 96.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          kg == 0 ? '–' : formatKg(kg).replaceAll(' kg', ''),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: current ? AppColors.primary : AppColors.muted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 26,
          height: kg == 0 ? 4 : 6 + (maxBarHeight - 6) * ratio,
          decoration: BoxDecoration(
            color: current ? AppColors.primary : AppColors.mintStrong,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: current ? FontWeight.w800 : FontWeight.w600,
            color: current ? AppColors.ink : AppColors.muted,
          ),
        ),
      ],
    );
  }
}
