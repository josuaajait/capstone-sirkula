import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../data/customer_store.dart';
import '../data/models.dart';
import '../widgets/common.dart';

/// Status dan rincian satu setoran (FR-C6).
class DepositDetailPage extends StatelessWidget {
  const DepositDetailPage({super.key, required this.deposit});
  final Deposit deposit;

  @override
  Widget build(BuildContext context) {
    // Ikut rebuild saat store berubah agar status selalu terbaru.
    CustomerScope.of(context);
    final d = deposit;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Setoran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.id,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    StatusPill.deposit(d.status),
                  ],
                ),
                const SizedBox(height: 12),
                InfoRow('Mitra', d.partner.name),
                InfoRow('Jenis sampah', d.type.label),
                InfoRow('Perkiraan berat', formatKg(d.estimatedKg)),
                InfoRow(
                  'Berat timbang',
                  d.weighedKg == null
                      ? 'Belum ditimbang'
                      : formatKg(d.weighedKg!),
                ),
                InfoRow('Metode', d.method.label),
                if (d.pickupDate != null)
                  InfoRow(
                    'Jadwal jemput',
                    '${formatDateLong(d.pickupDate!)}\n${d.pickupSlot} WIB',
                  ),
                if (d.address != null) InfoRow('Alamat', d.address!),
                if (d.vehicle != null) InfoRow('Kendaraan', d.vehicle!),
                if (d.note != null) InfoRow('Catatan', d.note!),
                const Divider(height: 24, color: AppColors.line),
                if (d.earnedPoints != null)
                  InfoRow(
                    'Poin diterima',
                    '+${formatNumber(d.earnedPoints!)} poin',
                    valueColor: AppColors.emeraldDeep,
                  )
                else
                  InfoRow(
                    'Estimasi poin',
                    '±${formatNumber(d.estimatedPoints)} poin',
                    valueColor: AppColors.primary,
                  ),
              ],
            ),
          ),
          if (d.earnedPoints == null) ...[
            const SizedBox(height: 12),
            const Text(
              'Poin final dihitung sistem dari berat hasil timbang mitra, jadi bisa berbeda dari estimasi.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ],
          if (d.weighedKg != null) ...[
            const SizedBox(height: 16),
            _WeighProof(deposit: d),
          ],
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Status Setoran'),
                const SizedBox(height: 16),
                StatusTimeline(d.timeline),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bukti timbang dari mitra: berat, waktu, catatan, dan foto timbangan.
class _WeighProof extends StatelessWidget {
  const _WeighProof({required this.deposit});
  final Deposit deposit;

  @override
  Widget build(BuildContext context) {
    final d = deposit;
    final url = d.weighPhotoUrl;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'Bukti Timbang',
            subtitle: 'Dicatat mitra saat sampah ditimbang',
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: url != null
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      semanticLabel: 'Foto timbangan ${d.id}',
                      errorBuilder: (_, _, _) => const _PhotoPlaceholder(
                        'Foto timbangan gagal dimuat.',
                      ),
                    )
                  : const _PhotoPlaceholder(
                      'Foto timbangan belum diunggah mitra.',
                    ),
            ),
          ),
          const SizedBox(height: 10),
          InfoRow('Berat timbang', formatKg(d.weighedKg!)),
          if (d.weighedAt != null)
            InfoRow(
              'Waktu timbang',
              '${formatDate(d.weighedAt!)}, ${formatTime(d.weighedAt!)}',
            ),
          if (d.weighNote != null && d.weighNote!.isNotEmpty)
            InfoRow('Catatan mitra', d.weighNote!),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_camera_outlined,
            size: 28,
            color: AppColors.muted,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
