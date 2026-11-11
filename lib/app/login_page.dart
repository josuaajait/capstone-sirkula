import 'package:flutter/material.dart';

import '../customer/data/customer_store.dart';
import '../customer/widgets/common.dart';
import 'auth_background.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'session.dart';
import 'theme.dart';

/// Peran yang dipilih di tombol "Masuk sebagai …". Peran tetap terikat ke
/// akun (FR-A3): pilihan ini hanya dicocokkan dengan peran akun.
enum LoginAs {
  customer('Customer'),
  partner('Mitra'),
  company('Perusahaan');

  const LoginAs(this.label);
  final String label;

  static LoginAs of(UserRole role) => switch (role) {
    UserRole.customer => LoginAs.customer,
    UserRole.partner => LoginAs.partner,
  };
}

/// Masuk dengan nomor ponsel atau email dan kata sandi (FR-A2). Tampilan
/// mengikuti desain Figma Make "halaman login mobile".
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
  LoginAs _as = LoginAs.customer;
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
    setState(() {
      _error = null;
      _info = null;
    });
    if (!_formKey.currentState!.validate()) return;
    if (_as == LoginAs.company || isCompanyEmail(_id.text)) {
      setState(
        () => _error =
            'Peran Admin untuk staf perusahaan sedang disiapkan di aplikasi.',
      );
      return;
    }
    final account = authenticate(_id.text, _password.text);
    if (account == null) {
      setState(() => _error = 'Nomor ponsel/email atau kata sandi salah.');
      return;
    }
    final role = LoginAs.of(account.role);
    if (role != _as) {
      setState(
        () => _error =
            'Akun ini terdaftar sebagai ${role.label}. Pilih "Masuk sebagai ${role.label}".',
      );
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
      _id.text = a.phone;
      _password.text = DemoAccount.password;
      _as = LoginAs.of(a.role);
      _error = null;
      _info = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2F6E8),
      body: Stack(
        children: [
          const Positioned.fill(child: AuthBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Brand(),
                      const SizedBox(height: 20 + 36),
                      _card(),
                      const SizedBox(height: 16),
                      _demoAccounts(),
                      const SizedBox(height: 14),
                      const Text(
                        'Versi 1.0.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x38102D24),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Selamat Datang!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: _RolePicker(
                    value: _as,
                    onChanged: (v) => setState(() {
                      _as = v;
                      _error = null;
                    }),
                  ),
                ),
                const SizedBox(height: 18),
                _AuthField(
                  label: 'Nomor Handphone atau Email',
                  icon: Icons.phone_outlined,
                  controller: _id,
                  hint: '08xx xxxx xxxx',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Isi nomor handphone atau email.'
                      : null,
                ),
                const SizedBox(height: 14),
                _AuthField(
                  label: 'Kata Sandi',
                  icon: Icons.lock_outline_rounded,
                  controller: _password,
                  hint: '••••••••',
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Isi kata sandi.' : null,
                  suffix: IconButton(
                    tooltip: _obscure
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.subtle,
                    ),
                  ),
                ),
                if (_info != null && _error == null) ...[
                  const SizedBox(height: 12),
                  SuccessBanner(_info!),
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
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emeraldDeep,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  child: const Text('MASUK'),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: _forgot,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                    ),
                    child: const Text(
                      'Lupa Kata Sandi?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Belum Punya Akun?',
                      style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                    ),
                    TextButton(
                      onPressed: _register,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text(
                        'Daftar Disini',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Lencana ikon pengguna yang menumpang di tepi atas kartu.
        Positioned(
          top: -36,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.emeraldSoft,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _demoAccounts() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                if (a != demoAccounts.first) const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _fill(a),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Isi ${a.label}'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Logo bulat, nama aplikasi, dan slogan.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x38102D24),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/sirkula-logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sirkula',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Setor sampah, kami jemput ke rumah Anda',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

/// Tombol pil "Masuk sebagai …" dengan daftar pilihan peran.
class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.value, required this.onChanged});

  final LoginAs value;
  final ValueChanged<LoginAs> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LoginAs>(
      tooltip: 'Pilih peran',
      initialValue: value,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      itemBuilder: (_) => [
        for (final r in LoginAs.values)
          PopupMenuItem(
            value: r,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    r.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: r == value ? AppColors.primary : AppColors.muted,
                    ),
                  ),
                ),
                if (r == value)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        decoration: BoxDecoration(
          color: AppColors.emeraldSoft.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.emeraldDeep),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Masuk sebagai ${value.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Isian berlabel dengan ikon di kiri, seperti `AuthField` di desain.
class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            prefixIconConstraints: const BoxConstraints(minWidth: 42),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: border(AppColors.line),
            enabledBorder: border(AppColors.line),
            focusedBorder: border(AppColors.emeraldDeep, 1.5),
            errorBorder: border(AppColors.roseDeep),
            focusedErrorBorder: border(AppColors.roseDeep, 1.5),
          ),
        ),
      ],
    );
  }
}
