import 'package:flutter/material.dart';
import '../../core/di.dart';
import '../../ui/notifier.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final code = TextEditingController();
  final pass = TextEditingController();
  final pass2 = TextEditingController();
  String email = '';
  bool loading = false;
  final formKey = GlobalKey<FormState>();

  void _snack(String m, {bool error = false}) {
    if (error) {
      Notifier.error(m);
    } else {
      Notifier.info(m);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    email = (args?['email'] ?? '') as String;
  }

  @override
  void dispose() {
    code.dispose();
    pass.dispose();
    pass2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    if (pass.text != pass2.text) {
      _snack('Konfirmasi password tidak sama', error: true);
      return;
    }
    setState(() => loading = true);
    try {
      await DI.auth.verifyForgotOtp(email, code.text.trim(), pass.text);
      if (!mounted) return;
      _snack('Password direset. Silakan login.');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Email: $email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: code,
              decoration: const InputDecoration(labelText: 'Kode OTP (6 digit)'),
              keyboardType: TextInputType.number,
              validator: (v) =>
              (v == null || v.length < 4) ? 'Kode tidak valid' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: pass,
              decoration: const InputDecoration(labelText: 'Password baru'),
              obscureText: true,
              validator: (v) =>
              (v == null || v.length < 6) ? 'Min 6 karakter' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: pass2,
              decoration: const InputDecoration(labelText: 'Ulangi password baru'),
              obscureText: true,
              validator: (v) =>
              (v == null || v.length < 6) ? 'Min 6 karakter' : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: Text(loading ? 'Loading...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
