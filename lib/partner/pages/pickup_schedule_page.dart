import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../customer/data/models.dart';
import '../../customer/widgets/common.dart';
import '../data/partner_store.dart';
import '../partner_shell.dart';
import '../widgets/partner_widgets.dart';

/// Jadwal jemput dan kendaraan mitra (FR-M3).
class PickupSchedulePage extends StatelessWidget {
  const PickupSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = PartnerScope.of(context);
    final pickups = store.pickups;
    final dropOffs = store.readyToWeigh
        .where((d) => d.method == DepositMethod.dropOff)
        .toList();

    // Kelompokkan per tanggal jemput.
    final groups = <DateTime, List<Deposit>>{};
    for (final d in pickups) {
      final t = d.pickupDate ?? d.createdAt;
      groups.putIfAbsent(DateTime(t.year, t.month, t.day), () => []).add(d);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        const PageHeading(
          'Jadwal Jemput',
          'Penjemputan yang sudah diterima. Mitra menjemput dengan kendaraan sendiri, lalu menimbang di lokasi atau di bank sampah.',
        ),
        if (pickups.isEmpty)
          const EmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'Belum ada jadwal jemput',
            message: 'Terima permintaan penjemputan di tab Permintaan untuk mengisi jadwal.',
          ),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              _dayLabel(entry.key),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.muted,
                letterSpacing: 0.4,
              ),
            ),
          ),
          for (final d in entry.value) ...[
            _PickupCard(d),
            const SizedBox(height: 12),
          ],
        ],
        if (dropOffs.isNotEmpty) ...[
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: SectionTitle(
                    'Menunggu Diantar',
                    subtitle: 'Setoran antar sendiri yang sudah diterima',
                  ),
                ),
                const Divider(height: 1, color: AppColors.line),
                for (final d in dropOffs) ...[
                  ListTile(
                    onTap: () =>
                        PartnerShell.goTo(context, PartnerTab.weigh, weigh: d),
                    leading: InitialsTile(
                      d.customer.initials,
                      size: 38,
                      background: AppColors.mint,
                      foreground: AppColors.primary,
                    ),
                    title: Text(
                      '${d.customer.name} · ${d.type.label}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '±${formatKg(d.estimatedKg)} · ${d.id}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: const Text(
                      'Timbang',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (d != dropOffs.last)
                    const Divider(height: 1, color: AppColors.line),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _VehiclesCard(store: store),
      ],
    );
  }

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = day.difference(today).inDays;
    final name = formatDateLong(day).toUpperCase();
    if (diff == 0) return 'HARI INI · $name';
    if (diff == 1) return 'BESOK · $name';
    if (diff < 0) return 'TERLEWAT · $name';
    return name;
  }
}

class _PickupCard extends StatelessWidget {
  const _PickupCard(this.d);
  final Deposit d;

  @override
  Widget build(BuildContext context) {
    final store = PartnerScope.read(context);
    final onTheWay = d.status == DepositStatus.onTheWay;
    return AppCard(
      onTap: () => openPartnerDeposit(context, d),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(Icons.local_shipping_outlined, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.pickupSlot ?? '-'} WIB',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.customer.name} · ${d.type.label} ±${formatKg(d.estimatedKg)}',
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
          const SizedBox(height: 6),
          if (d.address != null)
            MetaLine(Icons.location_on_outlined, d.address!),
          MetaLine(Icons.phone_outlined, d.customer.phone),
          MetaLine(
            Icons.directions_car_outlined,
            d.vehicle ?? 'Kendaraan belum dipilih',
          ),
          if (d.note != null) MetaLine(Icons.sticky_note_2_outlined, d.note!),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final r = await showScheduleSheet(
                      context,
                      d,
                      accepting: false,
                    );
                    if (r == null || !context.mounted) return;
                    await runAction(
                      context,
                      () => store.reschedule(
                        d,
                        date: r.date,
                        slot: r.slot,
                        vehicle: r.vehicle,
                      ),
                    );
                  },
                  child: const Text('Ubah Jadwal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onTheWay
                      ? () => PartnerShell.goTo(
                          context,
                          PartnerTab.weigh,
                          weigh: d,
                        )
                      : () => runAction(context, () => store.depart(d)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(onTheWay ? 'Timbang' : 'Berangkat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehiclesCard extends StatelessWidget {
  const _VehiclesCard({required this.store});
  final PartnerStore store;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            'Kendaraan Mitra',
            subtitle: '${store.vehicles.length} kendaraan untuk menjemput',
            action: TextButton.icon(
              onPressed: () => _addVehicle(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Tambah',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final v in store.vehicles)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      v.type,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    v.plate,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addVehicle(BuildContext context) async {
    final type = TextEditingController();
    final plate = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kendaraan'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: type,
                decoration: const InputDecoration(
                  hintText: 'Jenis, misalnya Pikap',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Isi jenis kendaraan.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: plate,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Nomor polisi, misalnya B 1234 XY',
                ),
                validator: (v) =>
                    RegExp(r'^[A-Za-z]{1,2}\s?\d{1,4}\s?[A-Za-z]{0,3}$')
                        .hasMatch(v?.trim() ?? '')
                    ? null
                    : 'Nomor polisi tidak valid.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    // Controller tidak di-dispose di sini karena dialog masih beranimasi
    // menutup; keduanya dibersihkan GC.
    if (ok == true && context.mounted) {
      await runAction(context, () => store.addVehicle(type.text, plate.text));
    }
  }
}
