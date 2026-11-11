import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../customer/data/models.dart';
import '../../customer/widgets/common.dart';
import '../data/partner_store.dart';
import '../partner_shell.dart';
import '../widgets/partner_widgets.dart';

/// Catat timbangan (FR-M4, FR-M5, FR-M6).
///
/// Mitra memilih setoran yang sudah diterima, atau mencari customer yang
/// datang langsung lewat nomor ponsel/ID. Poin tampil otomatis dari berat dan
/// jenis, dan tidak bisa diketik mitra.
class WeighPage extends StatefulWidget {
  const WeighPage({super.key, this.request});

  final Deposit? request;

  @override
  State<WeighPage> createState() => _WeighPageState();
}

class _WeighPageState extends State<WeighPage> {
  final _formKey = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _weight = TextEditingController();
  final _note = TextEditingController();

  Deposit? _request;
  CustomerRef? _customer;
  WasteType _type = WasteType.plastik;
  String? _searchError;
  Deposit? _saved;

  @override
  void initState() {
    super.initState();
    final r = widget.request;
    if (r != null) _select(r);
  }

  @override
  void dispose() {
    _search.dispose();
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  void _select(Deposit d) {
    _request = d;
    _customer = d.customer;
    _type = d.type;
    _searchError = null;
    _weight.clear();
  }

  void _clearSelection() => setState(() {
    _request = null;
    _customer = null;
    _search.clear();
  });

  Future<void> _findCustomer() async {
    final store = PartnerScope.read(context);
    final query = _search.text;
    if (query.trim().isEmpty) {
      setState(() => _searchError = 'Isi nomor ponsel atau ID customer.');
      return;
    }
    final found = await runAction(
      context,
      () async => (await store.lookupCustomer(query),),
    );
    if (found == null || !mounted) return;
    final c = found.$1;
    setState(() {
      _request = null;
      _customer = c;
      _searchError = c == null
          ? 'Customer tidak ditemukan. Periksa nomor ponsel atau ID.'
          : null;
    });
  }

  double? get _kg {
    final v = parseKg(_weight.text);
    if (v == null || v <= 0 || v > maxWeighKg) return null;
    return (v * 10).round() / 10;
  }

  int get _points => _kg == null ? 0 : _type.pointsFor(_kg!);

  Future<void> _review() async {
    if (_customer == null) {
      setState(
        () => _searchError = 'Pilih setoran atau cari customer lebih dulu.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final store = PartnerScope.read(context);
    final kg = _kg!;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (context) => _ConfirmSheet(
        customer: _customer!,
        request: _request,
        type: _type,
        kg: kg,
        points: _type.pointsFor(kg),
        note: _note.text.trim(),
        partnerName: store.partner.name,
      ),
    );
    if (ok != true || !mounted) return;
    final saved = await runAction(
      context,
      () => store.recordWeighing(
        request: _request,
        customer: _customer!,
        type: _type,
        kg: kg,
        note: _note.text,
      ),
    );
    if (saved == null || !mounted) return;
    setState(() => _saved = saved);
  }

  @override
  Widget build(BuildContext context) {
    final store = PartnerScope.of(context);
    if (_saved != null) return _SavedView(deposit: _saved!);

    final ready = store.readyToWeigh;
    final customer = _customer;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          const PageHeading(
            'Catat Timbangan',
            'Timbang sampah customer lalu catat beratnya. Poin dihitung otomatis oleh sistem.',
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  '1. Customer',
                  subtitle: 'Pilih setoran yang sudah diterima, atau cari customer yang datang langsung.',
                ),
                const SizedBox(height: 14),
                if (customer != null)
                  _CustomerCard(
                    customer: customer,
                    balance: store.balanceOf(customer),
                    request: _request,
                    onClear: _clearSelection,
                  )
                else ...[
                  const FieldLabel('Nomor ponsel atau ID customer'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _findCustomer(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: '0812… atau CST-0001',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                            ),
                            errorText: _searchError,
                            errorMaxLines: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 76,
                        child: FilledButton(
                          onPressed: _findCustomer,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(76, 48),
                          ),
                          child: const Text('Cari'),
                        ),
                      ),
                    ],
                  ),
                  if (ready.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const FieldLabel('Atau pilih setoran yang sudah diterima'),
                    for (final d in ready)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ReadyTile(
                          d,
                          onTap: () => setState(() => _select(d)),
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  '2. Hasil Timbang',
                  subtitle: 'Pilih jenis yang sebenarnya, lalu isi berat sampai 0,1 kg.',
                ),
                const SizedBox(height: 14),
                const FieldLabel('Jenis sampah'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in store.partner.accepts)
                      ChoiceChip(
                        avatar: Icon(t.icon, size: 16),
                        label: Text(t.label),
                        selected: _type == t,
                        onSelected: (_) => setState(() => _type = t),
                      ),
                  ],
                ),
                if (_request != null && _request!.type != _type)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Berbeda dari permintaan (${_request!.type.label}). Customer akan melihat jenis hasil timbang.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.amberDeep,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const FieldLabel('Berat hasil timbang'),
                TextFormField(
                  key: const ValueKey('weigh-kg'),
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d?')),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: _request == null
                        ? 'Contoh: 4,8'
                        : 'Perkiraan customer ${formatKg(_request!.estimatedKg)}',
                    suffixText: 'kg',
                  ),
                  validator: (v) {
                    final kg = parseKg(v ?? '');
                    if (kg == null || kg <= 0) {
                      return 'Isi berat lebih dari 0 kg.';
                    }
                    if (kg > maxWeighKg) {
                      return 'Maksimal ${formatKg(maxWeighKg)} per setoran. Pecah menjadi beberapa setoran.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const FieldLabel('Catatan (opsional)'),
                TextField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: sebagian botol masih ada label',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PointsPanel(type: _type, kg: _kg, points: _points),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _review,
            child: const Text('Tinjau & Simpan'),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.balance,
    required this.request,
    required this.onClear,
  });

  final CustomerRef customer;
  final int balance;
  final Deposit? request;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mintStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsTile(customer.initials, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${customer.id} · Saldo ${formatNumber(balance)} poin',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ganti customer',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request == null
                ? 'Setoran baru · customer datang langsung'
                : '${request!.id} · ${request!.method.label} · perkiraan ${formatKg(request!.estimatedKg)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyTile extends StatelessWidget {
  const _ReadyTile(this.d, {required this.onTap});
  final Deposit d;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              InitialsTile(
                d.customer.initials,
                size: 34,
                background: AppColors.white,
                foreground: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${d.customer.name} · ${d.type.label}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '±${formatKg(d.estimatedKg)} · ${d.method.label}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.subtle),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointsPanel extends StatelessWidget {
  const _PointsPanel({
    required this.type,
    required this.kg,
    required this.points,
  });

  final WasteType type;
  final double? kg;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'POIN UNTUK CUSTOMER',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Dihitung sistem',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${formatNumber(points)} poin',
            key: const ValueKey('weigh-points'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.lime,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${kg == null ? '0 kg' : formatKg(kg!)} × ${formatNumber(type.pointsPerKg)} poin/kg ${type.lowerLabel}, dibulatkan ke bawah',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan sebelum disimpan (M07).
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.customer,
    required this.request,
    required this.type,
    required this.kg,
    required this.points,
    required this.note,
    required this.partnerName,
  });

  final CustomerRef customer;
  final Deposit? request;
  final WasteType type;
  final double kg;
  final int points;
  final String note;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Periksa Hasil Timbang',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Setelah disimpan, poin langsung masuk ke saldo customer.',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            InfoRow('Customer', '${customer.name} (${customer.id})'),
            InfoRow('Setoran', request?.id ?? 'Baru, datang langsung'),
            InfoRow('Bank sampah', partnerName),
            InfoRow('Jenis', type.label),
            InfoRow('Berat timbang', formatKg(kg)),
            if (request != null)
              InfoRow('Perkiraan customer', formatKg(request!.estimatedKg)),
            if (note.isNotEmpty) InfoRow('Catatan', note),
            const Divider(height: 24, color: AppColors.line),
            InfoRow(
              'Poin dari sistem',
              '${formatSignedPoints(points)} poin',
              valueColor: AppColors.emeraldDeep,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan Timbangan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Periksa Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedView extends StatelessWidget {
  const _SavedView({required this.deposit});
  final Deposit deposit;

  @override
  Widget build(BuildContext context) {
    final d = deposit;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        SuccessBanner(
          '${d.id} tersimpan. ${formatNumber(d.earnedPoints!)} poin masuk ke saldo ${d.customer.name}.',
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Ringkasan Setoran'),
              const SizedBox(height: 8),
              InfoRow('Customer', d.customer.name),
              InfoRow('Jenis', d.type.label),
              InfoRow('Berat timbang', formatKg(d.weighedKg!)),
              InfoRow(
                'Poin diberikan',
                '${formatSignedPoints(d.earnedPoints!)} poin',
                valueColor: AppColors.emeraldDeep,
              ),
              InfoRow('Waktu', formatStamp(d.weighedAt!)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => PartnerShell.goTo(context, PartnerTab.weigh),
          child: const Text('Catat Setoran Lain'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => openPartnerDeposit(context, d),
          child: const Text('Lihat Detail'),
        ),
      ],
    );
  }
}
