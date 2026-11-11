import 'package:flutter/material.dart';

import '../customer/widgets/common.dart';
import 'session.dart';
import 'theme.dart';

/// Pemulihan kata sandi (FR-A5): masukkan email/ponsel, isi kode
/// verifikasi, lalu buat kata sandi baru.
///
/// Kode di sini tiruan. Saluran pengiriman kode (SMS atau email) diputuskan
/// saat backend dibuat, karena PRD membatasi notifikasi ke dalam aplikasi.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialId = ''});

  final String initialId;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _id = TextEditingController(text: widget.initialId);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  DemoAccount? _account;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_id, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _sendCode() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (isCompanyEmail(_id.text)) {
      setState(
        () => _error = 'Akun staf perusahaan dipulihkan oleh admin Sirkula.',
      );
      return;
    }
    final account = findAccount(_id.text);
    if (account == null) {
      setState(() => _error = 'Akun dengan email/nomor ini tidak ditemukan.');
      return;
    }
    setState(() => _account = account);
  }

  void _reset() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_code.text.trim() != demoResetCode) {
      setState(() => _error = 'Kode verifikasi salah.');
      return;
    }
    resetPassword(_account!, _password.text);
    Navigator.of(context).pop(_account!.email);
  }

  String _mask(DemoAccount a) {
    final p = a.phone;
    return p.length < 6
        ? p
        : '${p.substring(0, 4)}${'•' * (p.length - 6)}${p.substring(p.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    const fieldStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    final account = _account;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lupa Kata Sandi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeading(
                      account == null
                          ? 'Pulihkan akun'
                          : 'Buat kata sandi baru',
                      account == null
                          ? 'Masukkan email atau nomor ponsel akun Anda. Kami kirim kode verifikasi.'
                          : 'Kode verifikasi dikirim ke ${_mask(account)}.',
                    ),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (account == null) ...[
                            const FieldLabel('Email atau nomor ponsel'),
                            TextFormField(
                              controller: _id,
                              keyboardType: TextInputType.emailAddress,
                              style: fieldStyle,
                              onFieldSubmitted: (_) => _sendCode(),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Isi email atau nomor ponsel.'
                                  : null,
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.amberSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Mode demo: kode verifikasi adalah $demoResetCode.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.amberDeep,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const FieldLabel('Kode verifikasi'),
                            TextFormField(
                              controller: _code,
                              keyboardType: TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              maxLength: 6,
                              style: fieldStyle,
                              decoration: const InputDecoration(
                                hintText: '6 digit',
                                counterText: '',
                              ),
                              validator: (v) =>
                                  RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '')
                                  ? null
                                  : 'Isi 6 digit kode verifikasi.',
                            ),
                            const SizedBox(height: 16),
                            const FieldLabel('Kata sandi baru'),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.newPassword],
                              style: fieldStyle,
                              decoration: InputDecoration(
                                hintText: 'Minimal 8 karakter, huruf dan angka',
                                suffixIcon: IconButton(
                                  tooltip: _obscure
                                      ? 'Tampilkan kata sandi'
                                      : 'Sembunyikan kata sandi',
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                ),
                              ),
                              validator: validatePassword,
                            ),
                            const SizedBox(height: 16),
                            const FieldLabel('Ulangi kata sandi baru'),
                            TextFormField(
                              controller: _confirm,
                              obscureText: _obscure,
                              style: fieldStyle,
                              onFieldSubmitted: (_) => _reset(),
                              validator: (v) => v != _password.text
                                  ? 'Kata sandi tidak sama.'
                                  : null,
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.roseDeep,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: account == null ? _sendCode : _reset,
                            child: Text(
                              account == null
                                  ? 'Kirim Kode'
                                  : 'Simpan Kata Sandi',
                            ),
                          ),
                          if (account != null) ...[
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: () => setState(() {
                                _account = null;
                                _error = null;
                              }),
                              child: const Text('Ganti email/nomor'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
