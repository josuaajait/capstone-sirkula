import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../customer/data/models.dart';
import '../../customer/widgets/common.dart';
import '../data/partner_store.dart';
import '../pages/partner_deposit_detail_page.dart';

class PartnerStatCard extends StatelessWidget {
  const PartnerStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon, size: 36),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: AppColors.subtle),
          ),
        ],
      ),
    );
  }
}

/// Baris ikon + teks kecil.
class MetaLine extends StatelessWidget {
  const MetaLine(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu baris setoran di sisi mitra. Ketuk untuk detail.
class PartnerDepositTile extends StatelessWidget {
  const PartnerDepositTile(this.deposit, {super.key});
  final Deposit deposit;

  @override
  Widget build(BuildContext context) {
    final d = deposit;
    final kg = d.weighedKg ?? d.estimatedKg;
    final String points;
    final Color pointsColor;
    if (d.earnedPoints != null) {
      points = '${formatSignedPoints(d.earnedPoints!)} poin';
      pointsColor = AppColors.emeraldDeep;
    } else if (d.status == DepositStatus.rejected) {
      points = '—';
      pointsColor = AppColors.subtle;
    } else {
      points = '±${formatNumber(d.estimatedPoints)} poin';
      pointsColor = AppColors.subtle;
    }

    return InkWell(
      onTap: () => openPartnerDeposit(context, d),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            InitialsTile(
              d.customer.initials,
              size: 40,
              background: AppColors.mint,
              foreground: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${d.customer.name} · ${d.type.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${formatDate(d.weighedAt ?? d.createdAt)} · ${formatKg(kg)}${d.weighedKg == null ? ' (perkiraan)' : ''}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.subtle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  points,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: pointsColor,
                  ),
                ),
                const SizedBox(height: 4),
                StatusPill.deposit(d.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void openPartnerDeposit(BuildContext context, Deposit d) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => PartnerDepositDetailPage(deposit: d)),
  );
}

// ---------- Terima / jadwalkan / tolak ----------

/// Terima permintaan. Untuk penjemputan, mitra memilih tanggal, slot, dan
/// kendaraan lebih dulu. Mengembalikan true jika berhasil.
Future<bool> acceptRequest(BuildContext context, Deposit d) async {
  final store = PartnerScope.read(context);
  if (d.method == DepositMethod.dropOff) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terima setoran?'),
        content: Text(
          '${d.customer.name} akan mengantar ${d.type.lowerLabel} ±${formatKg(d.estimatedKg)} ke ${store.partner.name}. Timbang saat sampah tiba.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terima'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return false;
    final accepted = await runAction(context, () => store.accept(d));
    if (accepted != true) return false;
  } else {
    final result = await showScheduleSheet(context, d, accepting: true);
    if (result == null || !context.mounted) return false;
    final accepted = await runAction(
      context,
      () => store.accept(
        d,
        date: result.date,
        slot: result.slot,
        vehicle: result.vehicle,
      ),
    );
    if (accepted != true) return false;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${d.id} diterima. Customer sudah diberi kabar.')),
    );
  }
  return true;
}

typedef ScheduleChoice = ({DateTime date, String slot, Vehicle vehicle});

Future<ScheduleChoice?> showScheduleSheet(
  BuildContext context,
  Deposit d, {
  required bool accepting,
}) {
  return showModalBottomSheet<ScheduleChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.white,
    builder: (_) => PartnerScope(
      store: PartnerScope.read(context),
      child: _ScheduleSheet(deposit: d, accepting: accepting),
    ),
  );
}

class _ScheduleSheet extends StatefulWidget {
  const _ScheduleSheet({required this.deposit, required this.accepting});
  final Deposit deposit;
  final bool accepting;

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  late DateTime _date;
  late String _slot;
  Vehicle? _vehicle;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = widget.deposit;
    final requested = d.pickupDate;
    _date = requested == null || requested.isBefore(today) ? today : requested;
    _slot = d.pickupSlot ?? pickupSlots.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = PartnerScope.read(context);
    _vehicle ??=
        store.vehicles
            .where((v) => v.label == widget.deposit.vehicle)
            .firstOrNull ??
        store.vehicles.firstOrNull;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final store = PartnerScope.of(context);
    final d = widget.deposit;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.accepting
                    ? 'Terima & Jadwalkan Jemput'
                    : 'Ubah Jadwal Jemput',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${d.customer.name} · ${d.type.label} ±${formatKg(d.estimatedKg)}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              if (d.address != null)
                MetaLine(Icons.location_on_outlined, d.address!),
              if (d.pickupDate != null && widget.accepting)
                MetaLine(
                  Icons.schedule_rounded,
                  'Diminta customer: ${formatDateLong(d.pickupDate!)}, ${d.pickupSlot ?? '-'} WIB',
                ),
              const SizedBox(height: 18),
              const FieldLabel('Tanggal jemput'),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(formatDateLong(_date)),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: 16),
              const FieldLabel('Slot waktu'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in pickupSlots)
                    ChoiceChip(
                      label: Text(s),
                      selected: _slot == s,
                      onSelected: (_) => setState(() => _slot = s),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const FieldLabel('Kendaraan mitra'),
              if (store.vehicles.isEmpty)
                const Text(
                  'Belum ada kendaraan. Tambahkan di tab Jadwal.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.roseDeep),
                )
              else
                RadioGroup<Vehicle>(
                  groupValue: _vehicle,
                  onChanged: (v) => setState(() => _vehicle = v),
                  child: Column(
                    children: [
                      for (final v in store.vehicles)
                        RadioListTile<Vehicle>(
                          value: v,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            v.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _vehicle == null
                    ? null
                    : () => Navigator.pop<ScheduleChoice>(context, (
                        date: _date,
                        slot: _slot,
                        vehicle: _vehicle!,
                      )),
                child: Text(
                  widget.accepting ? 'Terima & Kirim Jadwal' : 'Simpan Jadwal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tolak permintaan dengan alasan. Mengembalikan true jika ditolak.
Future<bool> rejectRequest(BuildContext context, Deposit d) async {
  final store = PartnerScope.read(context);
  final reason = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.white,
    builder: (_) => _RejectSheet(deposit: d),
  );
  if (reason == null || !context.mounted) return false;
  final rejected = await runAction(context, () => store.reject(d, reason));
  if (rejected != true) return false;
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${d.id} ditolak.')));
  }
  return true;
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.deposit});
  final Deposit deposit;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  String? _reason;
  final _other = TextEditingController();

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  String? get _value {
    if (_reason == null) return null;
    if (_reason == 'Lainnya') {
      final t = _other.text.trim();
      return t.length < 5 ? null : t;
    }
    return _reason;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tolak Permintaan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Alasan dikirim ke ${widget.deposit.customer.name} lewat notifikasi aplikasi.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: [
                    for (final r in [...rejectReasons, 'Lainnya'])
                      RadioListTile<String>(
                        value: r,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          r,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_reason == 'Lainnya')
                TextField(
                  controller: _other,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Tulis alasan singkat',
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _value == null
                    ? null
                    : () => Navigator.pop(context, _value),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.roseDeep,
                ),
                child: const Text('Tolak Permintaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
