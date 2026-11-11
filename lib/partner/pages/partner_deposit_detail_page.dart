import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                if (d.originalWeighedKg != null)
                  InfoRow(
                    'Dikoreksi dari',
                    '${formatKg(d.originalWeighedKg!)} · ${d.correctionReason ?? '-'}',
                    valueColor: AppColors.amberDeep,
                  ),
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
            onPressed: () => runAction(context, () => store.depart(d)),
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
        if (!d.canCorrect) return const [];
        return [
          OutlinedButton.icon(
            onPressed: () => _correct(context, store, d),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Koreksi Berat'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Koreksi bisa dilakukan sampai ${Deposit.correctionDays} hari setelah ditimbang. Poin customer ikut disesuaikan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
        ];
      case DepositStatus.rejected:
        return const [];
    }
  }

  Future<void> _correct(
    BuildContext context,
    PartnerStore store,
    Deposit d,
  ) async {
    final result = await showModalBottomSheet<(double, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => _CorrectSheet(deposit: d),
    );
    if (result == null || !context.mounted) return;
    final saved = await runAction(
      context,
      () => store.correctWeight(d, result.$1, result.$2),
    );
    if (saved != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berat dikoreksi menjadi ${formatKg(saved.weighedKg!)}. Poin customer: ${formatNumber(saved.earnedPoints!)}.',
          ),
        ),
      );
    }
  }
}

class _CorrectSheet extends StatefulWidget {
  const _CorrectSheet({required this.deposit});
  final Deposit deposit;

  @override
  State<_CorrectSheet> createState() => _CorrectSheetState();
}

class _CorrectSheetState extends State<_CorrectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _kg = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _kg.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (parseKg(_kg.text)!, _reason.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.deposit;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Koreksi berat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Berat tercatat ${formatKg(d.weighedKg!)} (${formatNumber(d.earnedPoints!)} poin). Poin dihitung ulang dengan tarif saat ditimbang.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            const FieldLabel('Berat yang benar (kg)'),
            TextFormField(
              key: const ValueKey('correct-kg'),
              controller: _kg,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d?')),
              ],
              decoration: const InputDecoration(hintText: 'Contoh: 4,8'),
              validator: (v) {
                final kg = parseKg(v ?? '');
                if (kg == null || kg <= 0 || kg > maxWeighKg) {
                  return 'Isi berat antara 0,1 dan ${formatKg(maxWeighKg)}.';
                }
                if ((kg - d.weighedKg!).abs() < 0.05) {
                  return 'Berat baru sama dengan berat lama.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            const FieldLabel('Alasan koreksi'),
            TextFormField(
              key: const ValueKey('correct-reason'),
              controller: _reason,
              maxLength: 255,
              decoration: const InputDecoration(
                hintText: 'Contoh: salah ketik angka timbangan',
              ),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Tulis alasan (minimal 5 huruf).'
                  : null,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _submit,
              child: const Text('Simpan Koreksi'),
            ),
          ],
        ),
      ),
    );
  }
}
