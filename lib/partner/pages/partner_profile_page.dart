import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/session.dart';
import '../../app/theme.dart';
import '../../customer/widgets/common.dart';
import '../data/partner_store.dart';

/// Profil bank sampah mitra: data, jenis sampah dan poin per kg, kendaraan.
class PartnerProfilePage extends StatelessWidget {
  const PartnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = PartnerScope.of(context);
    final p = store.partner;
    final info = store.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Mitra')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            child: Column(
              children: [
                InitialsTile(p.initials, size: 72),
                const SizedBox(height: 12),
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.address}, ${p.area}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                const Pill('Mitra aktif'),
                const Divider(height: 28, color: AppColors.line),
                InfoRow('ID mitra', info.id),
                InfoRow('Penanggung jawab', info.owner),
                InfoRow('Nomor ponsel', info.phone),
                InfoRow('Email', info.email),
                InfoRow('Jam operasional', p.hours),
                InfoRow('Bergabung', formatDate(info.joined)),
                InfoRow('Target bulanan', formatKg(store.monthlyTargetKg)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  'Jenis Sampah & Poin per kg',
                  subtitle: 'Diatur perusahaan. Mitra tidak bisa mengubah angka poin.',
                ),
                const SizedBox(height: 8),
                for (final t in p.accepts)
                  InfoRow(t.label, '${formatNumber(t.pointsPerKg)} poin/kg'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Kendaraan'),
                const SizedBox(height: 8),
                for (final v in store.vehicles) InfoRow(v.type, v.plate),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              AppSession.logout(context);
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.roseDeep,
            ),
          ),
        ],
      ),
    );
  }
}
