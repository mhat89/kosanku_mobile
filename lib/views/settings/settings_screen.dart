import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/di.dart';
import '../../ui/notifier.dart';
import '../../services/biometric_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? email;
  ThemeMode _mode = ThemeMode.system;
  bool _bioAvail = false;
  bool _bioEnabled = false;
  List<BiometricType> _bioTypes = const [];

  @override
  void initState() {
    super.initState();
    DI.auth.getEmail().then((e) => setState(() => email = e));
    _mode = DI.theme.mode;
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    // availability() sekarang mengembalikan record (bool, String?, List<BiometricType>)
    final (ok, _reason, types) = await DI.biometric.availability();
    final enabled = await DI.biometric.isEnabled();
    if (!mounted) return;
    setState(() {
      _bioAvail = ok;
      _bioTypes = types;
      _bioEnabled = enabled;
    });
  }

  Widget _themeTile(String title, ThemeMode m, IconData icon) {
    final selected = _mode == m;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: selected ? const Icon(CupertinoIcons.check_mark_circled_solid) : null,
      onTap: () async {
        setState(() => _mode = m);
        await DI.theme.setMode(m);
      },
    );
  }

  String _bioLabel() {
    if (_bioTypes.contains(BiometricType.face)) return 'Face ID';
    if (_bioTypes.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (_bioTypes.contains(BiometricType.iris)) return 'Iris';
    // strong/weak atau credential → label generik
    return 'Biometrik';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(CupertinoIcons.person),
          title: const Text('Profile'),
          subtitle: Text(email ?? '-'),
        ),
        const Divider(),
        // Tema
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Tema', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        _themeTile('Ikuti Sistem', ThemeMode.system, CupertinoIcons.gear),
        _themeTile('Terang', ThemeMode.light, CupertinoIcons.sun_max),
        _themeTile('Gelap', ThemeMode.dark, CupertinoIcons.moon),
        const Divider(),
        // Ganti Password (tanpa OTP)
        ListTile(
          leading: const Icon(CupertinoIcons.lock),
          title: const Text('Ganti Password'),
          onTap: () => Navigator.pushNamed(context, '/change-password'),
        ),
        // Reset via OTP (lupa password)
        ListTile(
          leading: const Icon(CupertinoIcons.lock_rotation),
          title: const Text('Lupa Password (OTP)'),
          onTap: () => Navigator.pushNamed(context, '/forgot'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(CupertinoIcons.lock_open),
          title: const Text('Logout'),
          onTap: () async {
            await DI.auth.logout();
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          },
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Keamanan', style: TextStyle(fontWeight: FontWeight.w600)),
        ),

        if (_bioAvail)
    SwitchListTile.adaptive(
    title: Text('Gunakan ${_bioLabel()}'),
    subtitle: const Text('Kunci aplikasi saat dibuka'),
    value: _bioEnabled,
      onChanged: (v) async {
        if (v) {
          final (ok, err) = await DI.biometric.tryEnable();
          if (!ok) {
            Notifier.warn(err ?? 'Aktivasi dibatalkan atau tidak didukung');
            if (mounted) setState(() => _bioEnabled = false);
            return;
          }
          if (mounted) setState(() => _bioEnabled = true);
          Notifier.success('Kunci diaktifkan');
        } else {
          await DI.biometric.setEnabled(false);
          if (mounted) setState(() => _bioEnabled = false);
          Notifier.info('Kunci dimatikan');
        }
      },

    )
        else
          const ListTile(
            leading: Icon(CupertinoIcons.lock),
            title: Text('Biometrik tidak tersedia'),
            subtitle: Text('Perangkat tidak mendukung / belum didaftarkan'),
          ),

        const Divider(),
      ],
    );
  }
}
