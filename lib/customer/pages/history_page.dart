import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../data/customer_store.dart';
import '../widgets/activity_tile.dart';
import '../widgets/common.dart';

enum _Filter {
  all('Semua'),
  deposit('Setoran'),
  redemption('Penukaran hadiah');

  const _Filter(this.label);
  final String label;
}

/// Riwayat setoran dan penukaran (FR-C6, FR-C10).
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _search = TextEditingController();
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Activity a, String q) {
    if (_filter == _Filter.deposit && a.kind != ActivityKind.deposit) {
      return false;
    }
    if (_filter == _Filter.redemption && a.kind != ActivityKind.redemption) {
      return false;
    }
    if (q.isEmpty) return true;
    final d = a.deposit;
    final r = a.redemption;
    final haystack = [
      a.id,
      if (d != null) ...[d.partner.name, d.type.label, d.status.label],
      if (r != null) ...[r.reward.name, r.status.label],
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final store = CustomerScope.of(context);
    final q = _search.text.trim().toLowerCase();
    final items = store.activities.where((a) => _matches(a, q)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        PageHeading(
          'Riwayat Transaksi',
          'Semua aktivitas ${store.profile.name} di seluruh mitra.',
        ),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Cari ID, mitra, atau jenis sampah...',
            fillColor: AppColors.white,
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.subtle,
            ),
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
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.white,
                    side: BorderSide(
                      color: _filter == f ? AppColors.primary : AppColors.line,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _filter == f ? AppColors.white : AppColors.ink,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const EmptyState(
            icon: Icons.history_rounded,
            title: 'Tidak ada transaksi',
            message: 'Coba ubah kata kunci atau filter.',
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  ActivityTile(items[i], showStatus: true),
                  if (i < items.length - 1)
                    const Divider(height: 1, color: AppColors.line),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
