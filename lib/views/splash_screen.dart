import 'package:flutter/material.dart';
import '../core/di.dart';
import '../widgets/loading_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    // biar frame pertama sempat render
    await Future.microtask(() {});

    final hasToken = await DI.auth.hasToken();
    if (!hasToken) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // sudah login → cek apakah lock biometrik aktif
    final ok = await DI.biometric.gateOpen(reason: 'Buka Kosanku');
    if (!ok) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    Navigator.pushReplacementNamed(context, '/app');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF00BCD4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo aplikasi dengan animasi loading
            LoadingWidget(color: Colors.white, size: 60),
            SizedBox(height: 20),
            Text(
              'Kosanku',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}