import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
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
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganti Password'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubah Password Anda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Pastikan password baru Anda minimal 8 karakter',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: oldCtl,
                        decoration: InputDecoration(
                          labelText: 'Password Lama',
                          prefixIcon: Icon(CupertinoIcons.lock, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newCtl,
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          prefixIcon: Icon(CupertinoIcons.lock_shield, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: new2Ctl,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password Baru',
                          prefixIcon: Icon(CupertinoIcons.lock_shield_fill, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: loading
                              ? const CupertinoActivityIndicator(color: Colors.white)
                              : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
