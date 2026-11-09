import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../data/customer_store.dart';
import '../data/models.dart';
import '../pages/deposit_detail_page.dart';
import 'common.dart';

/// Satu baris aktivitas (setoran atau penukaran). Ketuk untuk melihat detail.
class ActivityTile extends StatelessWidget {
  const ActivityTile(this.activity, {super.key, this.showStatus = false});

  final Activity activity;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final d = activity.deposit;
    final r = activity.redemption;

    final String title;
    final String subtitle;
    final String points;
    final Color pointsColor;
    final IconData icon;
    final Widget status;

    if (d != null) {
      final kg = d.weighedKg ?? d.estimatedKg;
      title = 'Setoran ${d.type.lowerLabel} · ${d.partner.name}';
      subtitle =
          '${formatDate(d.createdAt)} · ${formatKg(kg)}${d.weighedKg == null ? ' (perkiraan)' : ''}';
      if (d.earnedPoints != null) {
        points = '${formatSignedPoints(d.earnedPoints!)} poin';
        pointsColor = AppColors.emeraldDeep;
      } else {
        points = '±${formatNumber(d.estimatedPoints)} poin';
        pointsColor = AppColors.subtle;
      }
      icon = Icons.move_to_inbox_outlined;
      status = StatusPill.deposit(d.status);
    } else {
      title = 'Penukaran ${r!.reward.name}';
      subtitle = formatDate(r.createdAt);
      points = '${formatSignedPoints(-r.reward.points)} poin';
      pointsColor = AppColors.roseDeep;
      icon = Icons.card_giftcard_outlined;
      status = StatusPill.redemption(r.status);
    }

    return InkWell(
      onTap: () {
        if (d != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DepositDetailPage(deposit: d)),
          );
        } else {
          showRedemptionSheet(context, r!);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            IconTile(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.subtle,
                    ),
                  ),
                  if (showStatus) ...[const SizedBox(height: 6), status],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              points,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: pointsColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail riwayat penukaran (FR-C10).
void showRedemptionSheet(BuildContext context, Redemption r) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.white,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsTile(
                  r.reward.initials,
                  size: 48,
                  background: r.reward.category.background,
                  foreground: r.reward.category.foreground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.reward.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusPill.redemption(r.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InfoRow('ID penukaran', r.id),
            InfoRow('Tanggal', formatDate(r.createdAt)),
            InfoRow(
              'Poin dipakai',
              '${formatNumber(r.reward.points)} poin',
              valueColor: AppColors.roseDeep,
            ),
            InfoRow('Alamat kirim', r.address),
            InfoRow('Nomor resi', r.trackingNumber ?? 'Belum tersedia'),
            const SizedBox(height: 10),
            const Text(
              'Hadiah disiapkan dan dikirim perusahaan dalam 1–2 hari kerja.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}
