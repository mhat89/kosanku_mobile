import 'package:flutter/material.dart';
import '../../core/di.dart';
import '../../ui/notifier.dart';
import 'dart:ui';

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
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: size.height,
          width: size.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.8),
                primaryColor.withOpacity(0.5),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.1),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Email: $email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.05),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: code,
                            decoration: InputDecoration(
                              labelText: 'Kode OTP (6 digit)',
                              prefixIcon: Icon(Icons.security_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                            (v == null || v.length < 4) ? 'Kode tidak valid' : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: pass,
                            decoration: InputDecoration(
                              labelText: 'Password baru',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            obscureText: true,
                            validator: (v) =>
                            (v == null || v.length < 6) ? 'Min 6 karakter' : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: pass2,
                            decoration: InputDecoration(
                              labelText: 'Ulangi password baru',
                              prefixIcon: Icon(Icons.lock_reset_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            obscureText: true,
                            validator: (v) =>
                            (v == null || v.length < 6) ? 'Min 6 karakter' : null,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: loading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'Simpan',
                                      style: TextStyle(fontSize: 18),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
