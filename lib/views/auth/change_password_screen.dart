import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/di.dart';
import '../../ui/notifier.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldCtl = TextEditingController();
  final newCtl = TextEditingController();
  final new2Ctl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool loading = false;

  @override
  void dispose() {
    oldCtl.dispose();
    newCtl.dispose();
    new2Ctl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    if (newCtl.text != new2Ctl.text) {
      Notifier.warn('Konfirmasi password baru tidak sama');
      return;
    }
    setState(() => loading = true);
    try {
      await DI.auth.changePassword(
        oldPassword: oldCtl.text,
        newPassword: newCtl.text,
        newPasswordConfirm: new2Ctl.text,
      );
      Notifier.success('Password berhasil diganti');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      Notifier.error('$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _field(String label, TextEditingController c) {
    return CupertinoTextField(
      controller: c,
      obscureText: true,
      placeholder: label,
      padding: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Ganti Password')),
      child: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Masukkan password lama dan password baru.'),
              const SizedBox(height: 12),
              _field('Password lama', oldCtl),
              const SizedBox(height: 12),
              _field('Password baru', newCtl),
              const SizedBox(height: 12),
              _field('Ulangi password baru', new2Ctl),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: loading ? null : _submit,
                child: Text(loading ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
