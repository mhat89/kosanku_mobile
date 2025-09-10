import 'package:flutter/material.dart';
import '../../core/di.dart';
import '../../ui/notifier.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await DI.auth.login(email.text.trim(), pass.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/app', (_) => false);
    } catch (e) {
      _snack('$e', error: true);
      final msg = e.toString().toLowerCase();
      if (msg.contains('belum aktif') || msg.contains('pending')) {
        Navigator.pushNamed(context, '/otp',
            arguments: {'email': email.text.trim()});
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
              (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: Text(loading ? 'Loading...' : 'Login'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/register'),
                    child: const Text('Register')),
                TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/forgot'),
                    child: const Text('Lupa Password')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
