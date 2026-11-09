import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../customer/data/models.dart';
import '../../customer/widgets/common.dart';
import '../data/partner_store.dart';
import '../partner_shell.dart';
import '../widgets/partner_widgets.dart';

/// Detail satu setoran di sisi mitra, beserta aksi sesuai statusnya.
class PartnerDepositDetailPage extends StatelessWidget {
  const PartnerDepositDetailPage({super.key, required this.deposit});
  final Deposit deposit;

  @override
  Widget build(BuildContext context) {
    final store = PartnerScope.of(context); // rebuild saat status berubah
    final d = deposit;
    final c = d.customer;

    return Scaffold(
      appBar: AppBar(title: Text(d.id)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    InitialsTile(c.initials, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${c.id} · ${c.phone}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusPill.deposit(d.status),
                  ],
                ),
                const Divider(height: 28, color: AppColors.line),
                InfoRow('Metode', d.method.label),
                InfoRow('Jenis', d.type.label),
                InfoRow('Perkiraan berat', formatKg(d.estimatedKg)),
                if (d.weighedKg != null)
                  InfoRow('Berat timbang', formatKg(d.weighedKg!)),
                InfoRow(
                  d.earnedPoints == null ? 'Estimasi poin' : 'Poin dari sistem',
                  d.earnedPoints == null
                      ? '±${formatNumber(d.estimatedPoints)} poin'
                      : '${formatSignedPoints(d.earnedPoints!)} poin',
                  valueColor: d.earnedPoints == null
                      ? null
                      : AppColors.emeraldDeep,
                ),
                if (d.pickupDate != null)
                  InfoRow(
                    'Jadwal jemput',
                    '${formatDateLong(d.pickupDate!)}, ${d.pickupSlot ?? '-'} WIB',
                  ),
                if (d.address != null) InfoRow('Alamat', d.address!),
                if (d.vehicle != null) InfoRow('Kendaraan', d.vehicle!),
                if (d.note != null) InfoRow('Catatan customer', d.note!),
                if (d.weighNote != null)
                  InfoRow('Catatan timbang', d.weighNote!),
                if (d.rejectReason != null)
                  InfoRow(
                    'Alasan ditolak',
                    d.rejectReason!,
                    valueColor: AppColors.roseDeep,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Status Setoran'),
                const SizedBox(height: 16),
                StatusTimeline(d.timeline),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._actions(context, store, d),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, PartnerStore store, Deposit d) {
    void weigh() {
      Navigator.of(context).pop();
      PartnerShell.goTo(context, PartnerTab.weigh, weigh: d);
    }

    switch (d.status) {
      case DepositStatus.waiting:
        return [
          FilledButton(
            onPressed: () async {
              final ok = await acceptRequest(context, d);
              if (ok && context.mounted) Navigator.of(context).pop();
            },
            child: Text(
              d.method == DepositMethod.pickup
                  ? 'Terima & Jadwalkan'
                  : 'Terima Setoran',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              final ok = await rejectRequest(context, d);
              if (ok && context.mounted) Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.roseDeep,
            ),
            child: const Text('Tolak'),
          ),
        ];
      case DepositStatus.scheduled when d.method == DepositMethod.pickup:
        return [
          FilledButton(
            onPressed: () => store.depart(d),
            child: const Text('Berangkat Menjemput'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: weigh,
            child: const Text('Catat Timbangan'),
          ),
        ];
      case DepositStatus.scheduled:
      case DepositStatus.onTheWay:
        return [
          FilledButton(onPressed: weigh, child: const Text('Catat Timbangan')),
        ];
      case DepositStatus.verified:
      case DepositStatus.rejected:
        return const [];
    }
  }
}
