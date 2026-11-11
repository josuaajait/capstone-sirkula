import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/session.dart';
import '../../app/theme.dart';
import '../../customer/data/models.dart';
import '../../customer/widgets/common.dart';
import '../admin_store.dart';
import 'admin_report_page.dart';

/// Menu pengaturan admin (FR-P2 sampai FR-P7).
class AdminManagePage extends StatelessWidget {
  const AdminManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    void open(Widget page) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminScope(store: store, child: page),
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        _MenuTile(
          icon: Icons.recycling_outlined,
          title: 'Jenis sampah & poin per kg',
          subtitle:
              '${store.wasteTypes.where((t) => t.isActive).length} jenis aktif',
          onTap: () => open(const _WasteTypesPage()),
        ),
        _MenuTile(
          icon: Icons.card_giftcard_outlined,
          title: 'Katalog hadiah',
          subtitle:
              '${store.rewards.where((r) => r.isActive).length} hadiah aktif',
          onTap: () => open(const _RewardsPage()),
        ),
        _MenuTile(
          icon: Icons.storefront_outlined,
          title: 'Data bank sampah',
          subtitle: store.bankSampah?.name ?? 'BSI Ias Toba',
          onTap: () => open(const _BankSampahPage()),
        ),
        _MenuTile(
          icon: Icons.badge_outlined,
          title: 'Petugas mitra',
          subtitle: '${store.staff.where((s) => s.isActive).length} akun aktif',
          onTap: () => open(const _StaffPage()),
        ),
        _MenuTile(
          icon: Icons.people_alt_outlined,
          title: 'Customer',
          subtitle: 'Daftar customer dan saldo poin',
          onTap: () => open(const _CustomersPage()),
        ),
        _MenuTile(
          icon: Icons.summarize_outlined,
          title: 'Laporan',
          subtitle: 'Berat, tCO2e, poin; unduh Excel atau PDF',
          onTap: () => open(const AdminReportPage()),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoRow('Nama', store.profile.name),
              InfoRow('Email', store.profile.email),
              InfoRow('ID', store.profile.code),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => AppSession.logout(context),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.roseDeep,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
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
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.subtle),
          ],
        ),
      ),
    );
  }
}

/// Kerangka halaman pengaturan.
class _SubPage extends StatelessWidget {
  const _SubPage({required this.title, required this.children, this.action});

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: action,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: children,
        ),
      ),
    );
  }
}

final _digitsOnly = [FilteringTextInputFormatter.digitsOnly];

// ---------- Jenis sampah (FR-P4) ----------

class _WasteTypesPage extends StatelessWidget {
  const _WasteTypesPage();

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    return _SubPage(
      title: 'Jenis Sampah',
      action: FloatingActionButton.extended(
        onPressed: () => _addType(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Perubahan poin per kg berlaku untuk timbangan berikutnya. Setoran lama tetap memakai tarif saat ditimbang.',
            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
        ),
        for (final g in WasteGroup.values) ...[
          SectionTitle(g.label),
          const SizedBox(height: 8),
          for (final t in store.wasteTypes.where((t) => t.group == g))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                onTap: () => _editType(context, t),
                child: Row(
                  children: [
                    IconTile(t.icon, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: t.isActive ? null : AppColors.subtle,
                            ),
                          ),
                          Text(
                            t.isActive ? t.examples : 'Nonaktif',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${formatNumber(t.pointsPerKg)}/kg',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _editType(BuildContext context, WasteType t) async {
    final store = AdminScope.read(context);
    final points = TextEditingController(text: '${t.pointsPerKg}');
    var active = t.isActive;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(t.label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: points,
                keyboardType: TextInputType.number,
                inputFormatters: _digitsOnly,
                decoration: const InputDecoration(labelText: 'Poin per kg'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                value: active,
                onChanged: (v) => setState(() => active = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    final value = int.tryParse(points.text);
    if (ok != true || value == null || !context.mounted) return;
    await runAction(
      context,
      () => store.updateWasteType(t, pointsPerKg: value, isActive: active),
    );
  }

  Future<void> _addType(BuildContext context) async {
    final store = AdminScope.read(context);
    final name = TextEditingController();
    final examples = TextEditingController();
    final points = TextEditingController();
    var group = WasteGroup.plastik;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Jenis sampah baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<WasteGroup>(
                  initialValue: group,
                  decoration: const InputDecoration(labelText: 'Kelompok'),
                  items: [
                    for (final g in WasteGroup.values)
                      DropdownMenuItem(value: g, child: Text(g.label)),
                  ],
                  onChanged: (v) => setState(() => group = v ?? group),
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                TextField(
                  controller: examples,
                  decoration: const InputDecoration(labelText: 'Contoh'),
                ),
                TextField(
                  controller: points,
                  keyboardType: TextInputType.number,
                  inputFormatters: _digitsOnly,
                  decoration: const InputDecoration(labelText: 'Poin per kg'),
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
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    final value = int.tryParse(points.text);
    if (ok != true || !context.mounted) return;
    if (name.text.trim().isEmpty || value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama dan poin per kg.')),
      );
      return;
    }
    await runAction(
      context,
      () => store.addWasteType(
        group: group,
        name: name.text,
        examples: examples.text,
        pointsPerKg: value,
      ),
    );
  }
}

// ---------- Katalog hadiah (FR-P5) ----------

class _RewardsPage extends StatelessWidget {
  const _RewardsPage();

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    return _SubPage(
      title: 'Katalog Hadiah',
      action: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      children: [
        for (final r in store.rewards)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              onTap: () => _edit(context, r),
              child: Row(
                children: [
                  InitialsTile(
                    r.initials,
                    background: r.category.background,
                    foreground: r.category.foreground,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: r.isActive ? null : AppColors.subtle,
                          ),
                        ),
                        Text(
                          '${r.category.label} · stok ${formatNumber(r.stock)}${r.isActive ? '' : ' · nonaktif'}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatNumber(r.points),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, Reward? r) async {
    final store = AdminScope.read(context);
    final name = TextEditingController(text: r?.name);
    final points = TextEditingController(text: r == null ? '' : '${r.points}');
    final stock = TextEditingController(text: r == null ? '' : '${r.stock}');
    final description = TextEditingController(text: r?.description);
    var category = r?.category ?? RewardCategory.voucher;
    var active = r?.isActive ?? true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(r == null ? 'Hadiah baru' : 'Ubah hadiah'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                DropdownButtonFormField<RewardCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [
                    for (final c in RewardCategory.values)
                      DropdownMenuItem(value: c, child: Text(c.label)),
                  ],
                  onChanged: (v) => setState(() => category = v ?? category),
                ),
                TextField(
                  controller: points,
                  keyboardType: TextInputType.number,
                  inputFormatters: _digitsOnly,
                  decoration: const InputDecoration(labelText: 'Harga poin'),
                ),
                TextField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  inputFormatters: _digitsOnly,
                  decoration: const InputDecoration(labelText: 'Stok'),
                ),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tampil di katalog'),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
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
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final p = int.tryParse(points.text);
    final s = int.tryParse(stock.text);
    if (name.text.trim().isEmpty || p == null || s == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama, harga poin, dan stok.')),
      );
      return;
    }
    await runAction(
      context,
      () => store.saveReward(
        existing: r,
        name: name.text,
        category: category,
        points: p,
        stock: s,
        description: description.text,
        isActive: active,
      ),
    );
  }
}

// ---------- Data bank sampah (FR-P2) ----------

class _BankSampahPage extends StatefulWidget {
  const _BankSampahPage();

  @override
  State<_BankSampahPage> createState() => _BankSampahPageState();
}

class _BankSampahPageState extends State<_BankSampahPage> {
  late final Partner? _p = AdminScope.read(context).bankSampah;
  late final _address = TextEditingController(text: _p?.address);
  late final _area = TextEditingController(text: _p?.area);
  late final _hours = TextEditingController(text: _p?.hours);
  late final _phone = TextEditingController(text: _p?.phone);
  late final _target = TextEditingController(
    text: _p == null ? '500' : _p.monthlyTargetKg.round().toString(),
  );
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_address, _area, _hours, _phone, _target]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final target = double.tryParse(_target.text);
    if (target == null) return;
    setState(() => _busy = true);
    final store = AdminScope.read(context);
    final ok = await runAction(context, () async {
      await store.updateBankSampah(
        address: _address.text,
        area: _area.text,
        hours: _hours.text,
        phone: _phone.text,
        monthlyTargetKg: target,
      );
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data bank sampah tersimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: _p?.name ?? 'Bank Sampah',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('Alamat'),
              TextField(controller: _address, maxLines: 2),
              const SizedBox(height: 12),
              const FieldLabel('Wilayah'),
              TextField(controller: _area),
              const SizedBox(height: 12),
              const FieldLabel('Jam buka'),
              TextField(controller: _hours),
              const SizedBox(height: 12),
              const FieldLabel('Kontak'),
              TextField(controller: _phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              const FieldLabel('Target bulanan (kg)'),
              TextField(
                controller: _target,
                keyboardType: TextInputType.number,
                inputFormatters: _digitsOnly,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- Petugas mitra (FR-P2) ----------

class _StaffPage extends StatelessWidget {
  const _StaffPage();

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    return _SubPage(
      title: 'Petugas Mitra',
      action: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Tambah'),
      ),
      children: [
        for (final u in store.staff)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
              child: Row(
                children: [
                  InitialsTile(
                    u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${u.name} · ${u.code}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${u.email} · ${u.phone}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: u.isActive,
                    onChanged: (v) =>
                        runAction(context, () => store.setStaffActive(u, v)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    final store = AdminScope.read(context);
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Akun petugas baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor ponsel'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi awal',
                  helperText: 'Minimal 8 karakter, huruf dan angka',
                ),
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await runAction(
      context,
      () => store.addStaff(
        name: name.text,
        email: email.text,
        phone: phone.text,
        password: password.text,
      ),
    );
  }
}

// ---------- Customer ----------

class _CustomersPage extends StatefulWidget {
  const _CustomersPage();

  @override
  State<_CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<_CustomersPage> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final store = AdminScope.read(context);
    await runAction(context, () => store.loadCustomers(search: _search.text));
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminScope.of(context);
    return _SubPage(
      title: 'Customer',
      children: [
        TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _load(),
          decoration: const InputDecoration(
            hintText: 'Cari nama, ID, email, atau ponsel',
            prefixIcon: Icon(Icons.search_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        for (final c in store.customers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c.name} · ${c.code}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${c.phone} · ${c.email}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${formatNumber(c.points)} poin',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
