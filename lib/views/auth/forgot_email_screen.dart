import 'package:flutter/material.dart';
import '../../core/di.dart';
import '../../ui/notifier.dart';
import 'dart:ui';

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
                      'Lupa Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Masukkan email untuk reset password',
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
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: email,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                            (v == null || v.isEmpty) ? 'Email wajib diisi' : null,
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
                                      'Kirim OTP Reset',
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
