import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../customer/data/models.dart';
import '../../customer/widgets/common.dart';
import '../data/partner_store.dart';
import '../widgets/partner_widgets.dart';

/// Daftar permintaan setoran dari customer (FR-M2): terima atau tolak.
class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = PartnerScope.of(context);
    final requests = store.requests;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        PageHeading(
          'Permintaan Setoran',
          'Customer yang memilih ${store.partner.name}. Terima untuk menjadwalkan, atau tolak jika sampah tidak memenuhi syarat.',
        ),
        const _Requirements(),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Belum ada permintaan baru',
            message: 'Permintaan dari customer akan muncul di sini, dan Anda mendapat notifikasi di aplikasi.',
          )
        else
          for (final d in requests) ...[
            _RequestCard(d),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _Requirements extends StatelessWidget {
  const _Requirements();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, size: 18, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Syarat sampah: bersih, kering, dan terpilah. Mitra boleh menolak sampah yang kotor atau tercampur.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryDark,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard(this.d);
  final Deposit d;

  @override
  Widget build(BuildContext context) {
    final pickup = d.method == DepositMethod.pickup;
    return AppCard(
      onTap: () => openPartnerDeposit(context, d),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsTile(d.customer.initials, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.customer.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.id} · ${formatStamp(d.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              Pill(
                d.method.label,
                background: pickup ? AppColors.blueSoft : AppColors.violetSoft,
                foreground: pickup ? AppColors.blueDeep : AppColors.violetDeep,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Fact('Jenis', d.type.label, d.type.icon),
              const SizedBox(width: 8),
              _Fact('Perkiraan', formatKg(d.estimatedKg), Icons.scale_outlined),
              const SizedBox(width: 8),
              _Fact(
                'Estimasi',
                '±${formatNumber(d.estimatedPoints)}',
                Icons.toll_outlined,
              ),
            ],
          ),
          if (pickup) ...[
            MetaLine(
              Icons.schedule_rounded,
              d.pickupDate == null
                  ? 'Jadwal belum dipilih customer'
                  : 'Diminta ${formatDateLong(d.pickupDate!)}, ${d.pickupSlot} WIB',
            ),
            if (d.address != null)
              MetaLine(Icons.location_on_outlined, d.address!),
          ] else
            const MetaLine(
              Icons.storefront_outlined,
              'Customer mengantar sendiri ke bank sampah',
            ),
          if (d.note != null) MetaLine(Icons.sticky_note_2_outlined, d.note!),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => rejectRequest(context, d),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.roseDeep,
                  ),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => acceptRequest(context, d),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(pickup ? 'Terima & Jadwalkan' : 'Terima'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: AppColors.subtle),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.subtle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
