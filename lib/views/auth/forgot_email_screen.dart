import 'package:flutter/material.dart';
import '../../core/di.dart';
import '../../ui/notifier.dart';

class ForgotEmailScreen extends StatefulWidget {
  const ForgotEmailScreen({super.key});
  @override
  State<ForgotEmailScreen> createState() => _ForgotEmailScreenState();
}

class _ForgotEmailScreenState extends State<ForgotEmailScreen> {
  final email = TextEditingController();
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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await DI.auth.forgotPassword(email.text.trim());
      if (!mounted) return;
      _snack('OTP reset dikirim. Masukkan OTP & password baru.');
      Navigator.pushNamed(context, '/reset',
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
      appBar: AppBar(title: const Text('Lupa Password')),
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
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: Text(loading ? 'Loading...' : 'Kirim OTP Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
