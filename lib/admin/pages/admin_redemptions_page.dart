import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../customer/data/models.dart';
import '../../customer/widgets/common.dart';
import '../admin_store.dart';

/// Memproses penukaran: kirim hadiah dengan nomor resi, lalu tandai selesai
/// (FR-P6).
class AdminRedemptionsPage extends StatefulWidget {
  const AdminRedemptionsPage({super.key});

  @override
  State<AdminRedemptionsPage> createState() => _AdminRedemptionsPageState();
}

class _AdminRedemptionsPageState extends State<AdminRedemptionsPage> {
  RedemptionStatus? _status = RedemptionStatus.processing;

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    final list = store.redemptions
        .where((r) => _status == null || r.redemption.status == _status)
        .toList();
    return RefreshIndicator(
      onRefresh: () => runAction(context, store.refresh),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in [...RedemptionStatus.values, null])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${s?.label ?? 'Semua'} (${store.redemptions.where((r) => s == null || r.redemption.status == s).length})',
                      ),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const EmptyState(
              icon: Icons.redeem_outlined,
              title: 'Tidak ada penukaran',
              message: 'Penukaran poin dari customer akan muncul di sini.',
            ),
          for (final r in list) ...[
            _RedemptionCard(r),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  const _RedemptionCard(this.item);
  final AdminRedemption item;

  @override
  Widget build(BuildContext context) {
    final r = item.redemption;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsTile(r.reward.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.reward.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${r.id} · ${formatStamp(r.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill.redemption(r.status),
            ],
          ),
          const SizedBox(height: 10),
          InfoRow('Customer', '${item.customerName} (${item.customerCode})'),
          InfoRow('Poin', formatNumber(r.reward.points)),
          InfoRow('Alamat kirim', r.address),
          if (r.trackingNumber != null) InfoRow('Resi', r.trackingNumber!),
          if (r.status != RedemptionStatus.done) ...[
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => r.status == RedemptionStatus.processing
                  ? _ship(context)
                  : _complete(context),
              child: Text(
                r.status == RedemptionStatus.processing
                    ? 'Kirim Hadiah'
                    : 'Tandai Selesai',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _ship(BuildContext context) async {
    final store = AdminScope.read(context);
    final controller = TextEditingController();
    final tracking = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim hadiah'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nomor resi atau kode voucher',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (tracking == null || tracking.isEmpty || !context.mounted) return;
    final ok = await runAction(context, () async {
      await store.shipRedemption(item, tracking);
      return true;
    });
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.redemption.id} dikirim. Customer diberi kabar.',
          ),
        ),
      );
    }
  }

  Future<void> _complete(BuildContext context) async {
    final store = AdminScope.read(context);
    await runAction(context, () => store.completeRedemption(item));
  }
}
