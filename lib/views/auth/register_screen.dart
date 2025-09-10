import 'package:flutter/material.dart';
import '../../core/di.dart';
import '../../ui/notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullName = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
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
  void dispose() {
    fullName.dispose();
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await DI.auth.register(email.text.trim(), pass.text, fullName.text);
      if (!mounted) return;
      _snack('Registrasi berhasil. OTP sudah dikirim ke email.');
      Navigator.pushNamed(context, '/otp',
          arguments: {'email': email.text.trim()});
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: fullName,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
              validator: (v) =>
              (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
              (v == null || v.isEmpty) ? 'Email wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: pass,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (v) =>
              (v == null || v.length < 6) ? 'Min 6 karakter' : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: Text(loading ? 'Loading...' : 'Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}
