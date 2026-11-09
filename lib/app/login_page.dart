import 'package:flutter/material.dart';

import '../customer/data/customer_store.dart';
import '../customer/widgets/common.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'session.dart';
import 'theme.dart';

/// Masuk dengan email atau nomor ponsel dan kata sandi (FR-A2). Tampilan
/// sesudahnya ditentukan oleh peran akun (FR-A3).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final ValueChanged<UserRole> onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (isCompanyEmail(_id.text)) {
      setState(
        () => _error =
            'Akun staf perusahaan masuk lewat panel admin, bukan aplikasi HP.',
      );
      return;
    }
    final account = authenticate(_id.text, _password.text);
    if (account == null) {
      setState(() => _error = 'Email/nomor ponsel atau kata sandi salah.');
      return;
    }
    _enter(account);
  }

  void _enter(DemoAccount account) {
    if (account.role == UserRole.customer) {
      CustomerScope.read(context).signInAs(
        email: account.email,
        name: account.label,
        phone: account.phone,
        address: account.address,
      );
    }
    widget.onLogin(account.role);
  }

  Future<void> _register() async {
    final account = await Navigator.of(context).push<DemoAccount>(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
    if (account != null && mounted) _enter(account);
  }

  Future<void> _forgot() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordPage(initialId: _id.text.trim()),
      ),
    );
    if (email == null || !mounted) return;
    setState(() {
      _id.text = email;
      _password.clear();
      _error = null;
      _info = 'Kata sandi berhasil diganti. Silakan masuk.';
    });
  }

  void _fill(DemoAccount a) {
    setState(() {
      _id.text = a.email;
      _password.text = DemoAccount.password;
      _error = null;
      _info = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/images/sirkula-logo.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Masuk ke Sirkula',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Untuk customer dan mitra bank sampah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 24),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const FieldLabel('Email atau nomor ponsel'),
                          TextFormField(
                            controller: _id,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'nama@email.com atau 0812…',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Isi email atau nomor ponsel.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('Kata sandi'),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Kata sandi',
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
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Isi kata sandi.'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgot,
                              child: const Text(
                                'Lupa kata sandi?',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          if (_info != null && _error == null)
                            SuccessBanner(_info!),
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
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _submit,
                            child: const Text('Masuk'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun?',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                        TextButton(
                          onPressed: _register,
                          child: const Text(
                            'Daftar sebagai customer',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AKUN DEMO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.subtle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final a in demoAccounts) ...[
                          if (a != demoAccounts.first)
                            const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _fill(a),
                              child: Text('Isi ${a.label}'),
                            ),
                          ),
                        ],
                      ],
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
