import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../data/customer_store.dart';
import '../data/models.dart';
import '../widgets/activity_tile.dart';
import '../widgets/common.dart';

/// Detail hadiah (FR-C8) dan konfirmasi penukaran dengan alamat kirim (FR-C9).
class RewardDetailPage extends StatelessWidget {
  const RewardDetailPage({super.key, required this.reward});
  final Reward reward;

  @override
  Widget build(BuildContext context) {
    final store = CustomerScope.of(context);
    final remaining = store.points - reward.points;
    final enough = remaining >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Hadiah',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: reward.category.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                reward.initials,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: reward.category.foreground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Pill(
            reward.category.label,
            background: reward.category.background,
            foreground: reward.category.foreground,
          ),
          const SizedBox(height: 8),
          Text(
            reward.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatNumber(reward.points)} poin',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reward.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                InfoRow('Saldo saat ini', '${formatNumber(store.points)} poin'),
                InfoRow(
                  'Harga hadiah',
                  '−${formatNumber(reward.points)} poin',
                  valueColor: AppColors.roseDeep,
                ),
                const Divider(height: 20, color: AppColors.line),
                InfoRow(
                  'Sisa saldo',
                  enough
                      ? '${formatNumber(remaining)} poin'
                      : 'Kurang ${formatNumber(-remaining)} poin',
                  valueColor: enough
                      ? AppColors.emeraldDeep
                      : AppColors.roseDeep,
                ),
                InfoRow('Stok', '${reward.stock} tersedia'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hadiah disediakan dan dikirim perusahaan dalam 1–2 hari kerja setelah penukaran.',
            style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: enough ? () => _redeem(context) : null,
            child: Text(enough ? 'Tukar Sekarang' : 'Poin belum cukup'),
          ),
        ),
      ),
    );
  }

  Future<void> _redeem(BuildContext context) async {
    final store = CustomerScope.read(context);
    final address = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => _RedeemSheet(
        reward: reward,
        balance: store.points,
        defaultAddress: store.profile.address,
      ),
    );
    if (address == null || !context.mounted) return;

    final redemption = store.redeem(reward, address);
    if (redemption == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saldo poin tidak cukup.')));
      return;
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${reward.name} berhasil ditukar dan sedang diproses.'),
        action: SnackBarAction(
          label: 'Lihat',
          textColor: AppColors.lime,
          onPressed: () => showRedemptionSheet(navigator.context, redemption),
        ),
      ),
    );
  }
}

class _RedeemSheet extends StatefulWidget {
  const _RedeemSheet({
    required this.reward,
    required this.balance,
    required this.defaultAddress,
  });

  final Reward reward;
  final int balance;
  final String defaultAddress;

  @override
  State<_RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends State<_RedeemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _address = TextEditingController(text: widget.defaultAddress);

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digital =
        widget.reward.category == RewardCategory.voucher ||
        widget.reward.category == RewardCategory.eWallet;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Konfirmasi Penukaran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                InfoRow('Hadiah', widget.reward.name),
                InfoRow(
                  'Poin dipakai',
                  '${formatNumber(widget.reward.points)} poin',
                ),
                InfoRow(
                  'Sisa saldo',
                  '${formatNumber(widget.balance - widget.reward.points)} poin',
                  valueColor: AppColors.emeraldDeep,
                ),
                const SizedBox(height: 14),
                FieldLabel(
                  digital
                      ? 'Alamat (untuk catatan pengiriman)'
                      : 'Alamat pengiriman',
                ),
                TextFormField(
                  controller: _address,
                  minLines: 2,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Isi alamat pengiriman lengkap.'
                      : null,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Poin langsung terpotong setelah dikonfirmasi.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).pop(_address.text.trim());
                    }
                  },
                  child: const Text('Konfirmasi Penukaran'),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
