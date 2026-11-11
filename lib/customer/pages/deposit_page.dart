import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../customer_shell.dart';
import '../data/customer_store.dart';
import '../data/models.dart';
import '../widgets/common.dart';
import 'deposit_detail_page.dart';

/// Setor Sampah ke BSI Ias Toba: isi sampah & berat (FR-C3), jadwal (FR-C4),
/// lalu tinjau sebelum kirim (FR-C5).
class DepositPage extends StatefulWidget {
  const DepositPage({super.key, this.preset});
  final DepositPreset? preset;

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController(text: '8');
  final _note = TextEditingController();
  late final TextEditingController _address;

  Partner get _partner => CustomerStore.bankSampah;
  WasteType _type = WasteType.plastik;
  DepositMethod _method = DepositMethod.dropOff;
  DateTime? _date;
  String _slot = pickupSlots.first;
  Deposit? _sent;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final store = CustomerScope.read(context);
    _method = widget.preset?.method ?? DepositMethod.dropOff;
    _address = TextEditingController(text: store.profile.address);
  }

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    _address.dispose();
    super.dispose();
  }

  double get _kg => parseKg(_weight.text) ?? 0;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year, now.month, now.day + 1),
      firstDate: DateTime(now.year, now.month, now.day + 1),
      lastDate: DateTime(now.year, now.month, now.day + 30),
      helpText: 'Pilih tanggal jemput',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _review() async {
    if (!_formKey.currentState!.validate()) return;
    if (_method == DepositMethod.pickup && _date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal jemput terlebih dahulu.')),
      );
      return;
    }
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => _ReviewSheet(
        partner: _partner,
        type: _type,
        kg: _kg,
        method: _method,
        date: _date,
        slot: _slot,
        address: _address.text.trim(),
        note: _note.text.trim(),
      ),
    );
    if (confirmed != true || !mounted) return;
    final store = CustomerScope.read(context);
    final deposit = await runAction(
      context,
      () => store.submitDeposit(
        partner: _partner,
        type: _type,
        estimatedKg: _kg,
        method: _method,
        pickupDate: _method == DepositMethod.pickup ? _date : null,
        pickupSlot: _method == DepositMethod.pickup ? _slot : null,
        address: _method == DepositMethod.pickup ? _address.text.trim() : null,
        note: _note.text,
      ),
    );
    if (deposit == null || !mounted) return;
    setState(() {
      _sent = deposit;
      _note.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    CustomerScope.of(context); // rebuild saat data customer berubah
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          const PageHeading(
            'Setor Sampah',
            'Isi detail setoran ke bank sampah BSI Ias Toba, lalu pilih antar sendiri atau dijemput.',
          ),
          if (_sent != null) ...[
            _SentBanner(deposit: _sent!),
            const SizedBox(height: 16),
          ],

          // ----- Detail setoran -----
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  'Detail Setoran ke ${_partner.name}',
                  subtitle:
                      'Berat akhir dikonfirmasi mitra setelah penimbangan.',
                ),
                const Divider(height: 28, color: AppColors.line),
                const FieldLabel('Kelompok sampah'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in WasteGroup.values)
                      if (_partner.accepts.any((t) => t.group == g))
                        ChoiceChip(
                          label: Text(g.label),
                          avatar: Icon(
                            g.icon,
                            size: 16,
                            color: g == _type.group
                                ? AppColors.white
                                : AppColors.primary,
                          ),
                          selected: g == _type.group,
                          showCheckmark: false,
                          onSelected: (_) => setState(
                            () => _type = g.types.firstWhere(
                              _partner.accepts.contains,
                            ),
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.canvas,
                          side: BorderSide(
                            color: g == _type.group
                                ? AppColors.primary
                                : AppColors.line,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: g == _type.group
                                ? AppColors.white
                                : AppColors.ink,
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 14),
                const FieldLabel('Jenis sampah'),
                for (final t in _type.group.types)
                  if (_partner.accepts.contains(t))
                    _WasteTypeOption(
                      type: t,
                      selected: t == _type,
                      onTap: () => setState(() => _type = t),
                    ),
                const SizedBox(height: 18),
                const FieldLabel('Estimasi berat'),
                TextFormField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  // Berat dicatat sampai 0,1 kg (aturan PRD).
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,3}([.,]\d?)?'),
                    ),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    suffixText: 'kg',
                    hintText: 'Contoh: 8,5',
                  ),
                  validator: (v) {
                    final kg = parseKg(v ?? '');
                    if (kg == null) return 'Isi perkiraan berat dalam kg.';
                    if (kg < 0.1) return 'Berat minimal 0,1 kg.';
                    if (kg > 500) return 'Berat maksimal 500 kg per setoran.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                const FieldLabel('Metode'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<DepositMethod>(
                    segments: const [
                      ButtonSegment(
                        value: DepositMethod.dropOff,
                        icon: Icon(Icons.storefront_outlined, size: 18),
                        label: Text('Antar sendiri'),
                      ),
                      ButtonSegment(
                        value: DepositMethod.pickup,
                        icon: Icon(Icons.local_shipping_outlined, size: 18),
                        label: Text('Dijemput'),
                      ),
                    ],
                    selected: {_method},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        setState(() => _method = s.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.mint,
                      selectedForegroundColor: AppColors.primary,
                      foregroundColor: AppColors.muted,
                      side: const BorderSide(color: AppColors.line),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (_method == DepositMethod.pickup) ...[
                  const SizedBox(height: 18),
                  const FieldLabel('Alamat penjemputan'),
                  TextFormField(
                    controller: _address,
                    minLines: 2,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Isi alamat lengkap penjemputan.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  const FieldLabel('Tanggal jemput'),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        suffixIcon: Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      child: Text(
                        _date == null
                            ? 'Pilih tanggal'
                            : formatDateLong(_date!),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _date == null
                              ? AppColors.subtle
                              : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const FieldLabel('Slot waktu'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in pickupSlots)
                        ChoiceChip(
                          label: Text(s),
                          selected: s == _slot,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _slot = s),
                          selectedColor: AppColors.mint,
                          backgroundColor: AppColors.canvas,
                          side: BorderSide(
                            color: s == _slot
                                ? AppColors.primary
                                : AppColors.line,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: s == _slot
                                ? AppColors.primary
                                : AppColors.ink,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                const FieldLabel('Catatan'),
                TextFormField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Tambahkan keterangan kondisi sampah...',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ----- Ringkasan mitra & estimasi poin -----
          _SelectedPartnerCard(partner: _partner, type: _type),
          const SizedBox(height: 12),
          _EstimateCard(type: _type, kg: _kg, partner: _partner),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _review,
            child: Text('Kirim Pengajuan ke ${_partner.name}'),
          ),
        ],
      ),
    );
  }
}

class _SelectedPartnerCard extends StatelessWidget {
  const _SelectedPartnerCard({required this.partner, required this.type});
  final Partner partner;
  final WasteType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BANK SAMPAH TUJUAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.lime,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            partner.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.white.withValues(alpha: 0.6),
            ),
          ),
          Divider(height: 26, color: AppColors.white.withValues(alpha: 0.12)),
          Text(
            '${partner.address}, ${partner.area}\n${partner.hours}',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.type,
    required this.kg,
    required this.partner,
  });

  final WasteType type;
  final double kg;
  final Partner partner;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimasi Poin',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatNumber(type.pointsFor(kg))} poin',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${formatKg(kg)} × ${formatNumber(type.pointsPerKg)} poin/kg (${type.label})',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const Divider(height: 26, color: AppColors.line),
          Text(
            'Ini hanya perkiraan. Poin final dihitung sistem dari berat hasil timbang ${partner.name}. Pastikan sampah bersih, kering, dan terpilah.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SentBanner extends StatelessWidget {
  const _SentBanner({required this.deposit});
  final Deposit deposit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SuccessBanner(
          'Pengajuan ${deposit.id} berhasil dikirim ke ${deposit.partner.name}. Kami kabari setelah mitra menerimanya.',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DepositDetailPage(deposit: deposit),
                  ),
                ),
                child: const Text('Lihat status'),
              ),
            ),
            if (deposit.method == DepositMethod.pickup) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      CustomerShell.goTo(context, CustomerTab.pickup),
                  child: const Text('Lacak penjemputan'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Tinjau sebelum mengirim (FR-C5).
class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet({
    required this.partner,
    required this.type,
    required this.kg,
    required this.method,
    required this.date,
    required this.slot,
    required this.address,
    required this.note,
  });

  final Partner partner;
  final WasteType type;
  final double kg;
  final DepositMethod method;
  final DateTime? date;
  final String slot;
  final String address;
  final String note;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tinjau Setoran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Periksa kembali sebelum mengirim ke mitra.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            InfoRow('Bank sampah', partner.name),
            InfoRow('Jenis sampah', type.label),
            InfoRow('Perkiraan berat', formatKg(kg)),
            InfoRow('Metode', method.label),
            if (method == DepositMethod.pickup) ...[
              InfoRow('Jadwal', '${formatDateLong(date!)}\n$slot WIB'),
              InfoRow('Alamat', address),
            ] else
              InfoRow('Antar ke', '${partner.address}\n${partner.hours}'),
            if (note.isNotEmpty) InfoRow('Catatan', note),
            const Divider(height: 24, color: AppColors.line),
            InfoRow(
              'Estimasi poin',
              '±${formatNumber(type.pointsFor(kg))} poin',
              valueColor: AppColors.primary,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Konfirmasi & Kirim'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ubah lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu pilihan jenis sampah rinci beserta contoh dan poin per kg.
class _WasteTypeOption extends StatelessWidget {
  const _WasteTypeOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final WasteType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? AppColors.mint : AppColors.canvas,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.line,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.subtle,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type.examples,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${formatNumber(type.pointsPerKg)}/kg',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
