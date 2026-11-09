import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../customer/data/models.dart';
import '../../customer/widgets/common.dart';
import '../data/partner_store.dart';
import '../widgets/partner_widgets.dart';

enum _Filter {
  all('Semua'),
  verified('Ditimbang'),
  active('Berjalan'),
  rejected('Ditolak');

  const _Filter(this.label);
  final String label;
}

/// Riwayat setoran yang diterima dan poin yang diberikan sistem (FR-M7).
class PartnerHistoryPage extends StatefulWidget {
  const PartnerHistoryPage({super.key});

  @override
  State<PartnerHistoryPage> createState() => _PartnerHistoryPageState();
}

class _PartnerHistoryPageState extends State<PartnerHistoryPage> {
  _Filter _filter = _Filter.all;
  String _query = '';

  bool _matches(Deposit d) {
    final okFilter = switch (_filter) {
      _Filter.all => true,
      _Filter.verified => d.status == DepositStatus.verified,
      _Filter.active => d.isActive,
      _Filter.rejected => d.status == DepositStatus.rejected,
    };
    if (!okFilter) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      d.id,
      d.customer.name,
      d.customer.id,
      d.type.label,
    ].any((s) => s.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final store = PartnerScope.of(context);
    final list = store.deposits.where(_matches).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        const PageHeading(
          'Riwayat Setoran',
          'Semua setoran customer yang masuk, beserta poin yang diberikan sistem.',
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            PartnerStatCard(
              icon: Icons.toll_outlined,
              label: 'Poin Bulan Ini',
              value: formatNumber(store.pointsThisMonth),
              note: 'Diberikan otomatis oleh sistem',
            ),
            PartnerStatCard(
              icon: Icons.scale_outlined,
              label: 'Berat Bulan Ini',
              value: formatKg(store.kgThisMonth),
              note: '${store.verifiedThisMonth.length} setoran ditimbang',
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Cari ID setoran, customer, atau jenis',
            prefixIcon: Icon(Icons.search_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in _Filter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Tidak ada setoran',
            message: 'Coba ubah kata kunci atau filter.',
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final d in list) ...[
                  PartnerDepositTile(d),
                  if (d != list.last)
                    const Divider(height: 1, color: AppColors.line),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
