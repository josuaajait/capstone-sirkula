import 'package:flutter/material.dart';

import '../customer/widgets/common.dart';
import 'session.dart';
import 'theme.dart';

/// Formulir daftar akun customer (FR-A4). Setelah berhasil, halaman ini
/// ditutup dengan akun baru sebagai hasilnya.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _agree = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _address, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      setState(() => _error = 'Setujui syarat sampah dan privasi data dulu.');
      return;
    }
    final error = registerCustomer(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      address: _address.text,
      password: _password.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(findAccount(_email.text));
  }

  InputDecoration _hint(String hint) => InputDecoration(hintText: hint);

  @override
  Widget build(BuildContext context) {
    const fieldStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Akun',
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
                    const PageHeading(
                      'Buat akun customer',
                      'Setor sampah terpilah ke bank sampah mitra dan kumpulkan poin.',
                    ),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const FieldLabel('Nama lengkap'),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            style: fieldStyle,
                            decoration: _hint('Nama sesuai identitas'),
                            validator: (v) => (v == null || v.trim().length < 3)
                                ? 'Isi nama lengkap (minimal 3 huruf).'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('Email'),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            style: fieldStyle,
                            decoration: _hint('nama@email.com'),
                            validator: (v) =>
                                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(v?.trim() ?? '')
                                ? null
                                : 'Email tidak valid.',
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('Nomor ponsel'),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            style: fieldStyle,
                            decoration: _hint('0812…'),
                            validator: (v) {
                              final n = normalizePhone(v ?? '');
                              return (n.startsWith('08') &&
                                      n.length >= 10 &&
                                      n.length <= 14)
                                  ? null
                                  : 'Nomor ponsel tidak valid (contoh 081234567890).';
                            },
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('Alamat penjemputan'),
                          TextFormField(
                            controller: _address,
                            minLines: 2,
                            maxLines: 3,
                            autofillHints: const [
                              AutofillHints.fullStreetAddress,
                            ],
                            style: fieldStyle,
                            decoration: _hint(
                              'Jalan, nomor rumah, RT/RW, kelurahan, kota',
                            ),
                            validator: (v) =>
                                (v == null || v.trim().length < 10)
                                ? 'Isi alamat lengkap.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('Kata sandi'),
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
                          const FieldLabel('Ulangi kata sandi'),
                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscure,
                            style: fieldStyle,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) => v != _password.text
                                ? 'Kata sandi tidak sama.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: _agree,
                            onChanged: (v) =>
                                setState(() => _agree = v ?? false),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                            title: const Text(
                              'Saya setuju menyetor sampah yang bersih, kering, dan terpilah, serta alamat dan nomor ponsel saya dipakai untuk penjemputan.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.roseDeep,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _submit,
                            child: const Text('Daftar'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Bank sampah yang ingin menjadi mitra didaftarkan oleh tim Sirkula.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
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
