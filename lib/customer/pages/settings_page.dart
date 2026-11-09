import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../widgets/common.dart';

/// Preferensi notifikasi customer. Disimpan di memori sampai backend siap.
class CustomerSettings {
  CustomerSettings._();

  static final pickupNotif = ValueNotifier(true);
  static final pointsNotif = ValueNotifier(true);
  static final rewardNotif = ValueNotifier(true);
  static final promoNotif = ValueNotifier(false);
}

/// Pengaturan akun customer (FR-C11).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 10, 18, 4),
                  child: SectionTitle(
                    'Notifikasi Aplikasi',
                    subtitle: 'Semua kabar dikirim lewat aplikasi.',
                  ),
                ),
                _Toggle(
                  'Permintaan & jadwal jemput',
                  'Saat mitra menerima, menolak, atau menuju lokasi',
                  CustomerSettings.pickupNotif,
                ),
                _Toggle(
                  'Poin masuk',
                  'Saat setoran selesai ditimbang',
                  CustomerSettings.pointsNotif,
                ),
                _Toggle(
                  'Status hadiah',
                  'Saat hadiah diproses dan dikirim',
                  CustomerSettings.rewardNotif,
                ),
                _Toggle(
                  'Info & promo',
                  'Hadiah baru dan program Sirkula',
                  CustomerSettings.promoNotif,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: const [
                InfoRow('Bahasa', 'Bahasa Indonesia'),
                InfoRow('Versi aplikasi', '1.0.0'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.title, this.subtitle, this.value);

  final String title;
  final String subtitle;
  final ValueNotifier<bool> value;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: value,
      builder: (context, on, _) => SwitchListTile(
        value: on,
        onChanged: (v) => value.value = v,
        activeThumbColor: AppColors.white,
        activeTrackColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ),
    );
  }
}
