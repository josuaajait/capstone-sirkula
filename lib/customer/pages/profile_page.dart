import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../app/theme.dart';
import '../data/customer_store.dart';
import '../widgets/common.dart';
import 'help_page.dart';
import 'settings_page.dart';

/// Profil customer: data akun dan alamat penjemputan (FR-C11).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final store = CustomerScope.read(context);
    final p = store.profile;
    _name = TextEditingController(text: p.name);
    _phone = TextEditingController(text: p.phone);
    _email = TextEditingController(text: p.email);
    _address = TextEditingController(text: p.address);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    CustomerScope.read(context).updateProfile(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
    );
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan profil tersimpan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = CustomerScope.of(context);
    final p = store.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Customer',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            AppCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  InitialsTile(p.initials, size: 76),
                  const SizedBox(height: 12),
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.id,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Pill(p.tier),
                  const Divider(height: 30, color: AppColors.line),
                  InfoRow('Bank sampah', 'BSI Ias Toba'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle(
                    'Informasi Pribadi',
                    subtitle: 'Kelola data akun dan alamat penjemputan.',
                  ),
                  const SizedBox(height: 18),
                  const FieldLabel('Nama lengkap'),
                  TextFormField(
                    controller: _name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Nomor telepon'),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      return digits.length < 9
                          ? 'Nomor telepon tidak valid.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Email'),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    validator: (v) =>
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Email tidak valid.',
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Alamat penjemputan'),
                  TextFormField(
                    controller: _address,
                    minLines: 3,
                    maxLines: 4,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Isi alamat lengkap.'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Simpan Perubahan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    label: 'Pengaturan',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  _MenuTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Bantuan',
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const HelpPage())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      leading: IconTile(icon, size: 36),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
    );
  }
}
