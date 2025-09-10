import 'package:flutter/material.dart';
import '../../core/di.dart';
import '../../ui/notifier.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final code = TextEditingController();
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
    super.dispose();
  }

  Future<void> _verify() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await DI.auth.verifyOtp(email, code.text.trim());
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/app', (_) => false);
    } catch (e) {
      _snack('$e', error: true);
      final msg = e.toString().toLowerCase();
      if (msg.contains('expired')) {
        try {
          await DI.auth.resendOtp(email);
          _snack('OTP baru dikirim.');
        } catch (e2) {
          _snack('$e2', error: true);
        }
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await DI.auth.resendOtp(email);
      _snack('OTP baru dikirim.');
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi OTP')),
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
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _verify,
              child: Text(loading ? 'Loading...' : 'Verifikasi'),
            ),
            TextButton(onPressed: _resend, child: const Text('Kirim Ulang OTP')),
          ],
        ),
      ),
    );
  }
}
