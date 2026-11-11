import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../customer/data/models.dart';
import '../../customer/widgets/common.dart';
import '../admin_store.dart';

/// Pantau setoran di BSI Ias Toba dengan pencarian dan filter status (FR-P3).
class AdminDepositsPage extends StatefulWidget {
  const AdminDepositsPage({super.key});

  @override
  State<AdminDepositsPage> createState() => _AdminDepositsPageState();
}

class _AdminDepositsPageState extends State<AdminDepositsPage> {
  final _search = TextEditingController();
  DepositStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final store = AdminScope.read(context);
    await runAction(
      context,
      () => store.loadDeposits(search: _search.text, status: _status),
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final deposits = store.deposits;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Cari kode setoran, nama, ID, atau ponsel',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: IconButton(
                tooltip: 'Cari',
                onPressed: _load,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in [null, ...DepositStatus.values])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s?.label ?? 'Semua'),
                      selected: _status == s,
                      onSelected: (_) {
                        setState(() => _status = s);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loading && deposits.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (deposits.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Tidak ada setoran',
              message: 'Coba ubah kata kunci atau filter status.',
            )
          else
            for (final d in deposits) ...[
              _DepositTile(d),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _DepositTile extends StatelessWidget {
  const _DepositTile(this.d);
  final Deposit d;

  @override
  Widget build(BuildContext context) {
    final kg = d.weighedKg ?? d.estimatedKg;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showDetail(context, d),
      child: Row(
        children: [
          IconTile(d.type.icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.customer.name} · ${d.customer.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${d.id} · ${d.type.label} ${d.weighedKg == null ? '±' : ''}${formatKg(kg)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatStamp(d.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.subtle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill.deposit(d.status),
              if (d.earnedPoints != null) ...[
                const SizedBox(height: 6),
                Text(
                  '+${formatNumber(d.earnedPoints!)} poin',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emeraldDeep,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

void _showDetail(BuildContext context, Deposit d) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.white,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.id,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusPill.deposit(d.status),
            ],
          ),
          const SizedBox(height: 12),
          InfoRow('Customer', '${d.customer.name} (${d.customer.id})'),
          if (d.customer.phone.isNotEmpty) InfoRow('Ponsel', d.customer.phone),
          InfoRow('Jenis', d.type.label),
          InfoRow('Perkiraan', formatKg(d.estimatedKg)),
          if (d.weighedKg != null)
            InfoRow('Berat timbang', formatKg(d.weighedKg!)),
          if (d.earnedPoints != null)
            InfoRow('Poin', formatNumber(d.earnedPoints!)),
          InfoRow('Cara', d.method.label),
          if (d.pickupDate != null)
            InfoRow(
              'Jadwal jemput',
              '${formatDateShort(d.pickupDate!)}, ${d.pickupSlot ?? '-'}',
            ),
          if (d.vehicle != null) InfoRow('Kendaraan', d.vehicle!),
          if (d.address != null && d.address!.isNotEmpty)
            InfoRow('Alamat', d.address!),
          if (d.note != null) InfoRow('Catatan customer', d.note!),
          if (d.weighNote != null) InfoRow('Catatan timbang', d.weighNote!),
          if (d.rejectReason != null) InfoRow('Alasan tolak', d.rejectReason!),
          const SizedBox(height: 16),
          const SectionTitle('Garis waktu'),
          const SizedBox(height: 10),
          StatusTimeline(d.timeline),
        ],
      ),
    ),
  );
}
