import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../customer_shell.dart';
import '../data/customer_store.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import 'deposit_detail_page.dart';

class PickupPage extends StatelessWidget {
  const PickupPage({super.key});

  void _request(BuildContext context) => CustomerShell.goTo(
    context,
    CustomerTab.deposit,
    preset: const DepositPreset(method: DepositMethod.pickup),
  );

  @override
  Widget build(BuildContext context) {
    final store = CustomerScope.of(context);
    final pickups = store.activePickups;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        const PageHeading(
          'Penjemputan',
          'Pantau jadwal jemput oleh mitra bank sampah pilihan Anda.',
        ),
        FilledButton.icon(
          onPressed: () => _request(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Minta Penjemputan'),
        ),
        const SizedBox(height: 16),
        if (pickups.isEmpty)
          const EmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'Belum ada penjemputan aktif',
            message: 'Ajukan setoran dengan metode "Dijemput" dan mitra akan datang ke alamat Anda.',
          )
        else
          for (final p in pickups) ...[
            _ActivePickupCard(deposit: p),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Status Penjemputan'),
                  const SizedBox(height: 16),
                  StatusTimeline(p.timeline),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
      ],
    );
  }
}

class _ActivePickupCard extends StatelessWidget {
  const _ActivePickupCard({required this.deposit});
  final Deposit deposit;

  @override
  Widget build(BuildContext context) {
    final d = deposit;
    return AppCard(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => DepositDetailPage(deposit: d))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PENJEMPUTAN AKTIF',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d.pickupDate == null
                          ? 'Menunggu jadwal'
                          : formatDateLong(d.pickupDate!),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Estimasi tiba ${d.pickupSlot ?? '-'} WIB',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StatusPill.deposit(d.status),
                  ],
                ),
              ),
              const IconTile(Icons.local_shipping_outlined, size: 48),
            ],
          ),
          const Divider(height: 28, color: AppColors.line),
          Row(
            children: [
              _InfoBox('Mitra', d.partner.name),
              const SizedBox(width: 8),
              _InfoBox('Kendaraan', d.vehicle ?? 'Belum ditentukan'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoBox(
                'Estimasi',
                '${formatKg(d.estimatedKg)} ${d.type.lowerLabel}',
              ),
              const SizedBox(width: 8),
              _InfoBox('ID setoran', d.id),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Alamat Penjemputan',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  d.address ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.subtle),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
