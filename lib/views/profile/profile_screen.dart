import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/di.dart';
import '../../ui/notifier.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/biometric_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? email;
  String? fullName;
  bool isLoading = true;
  ThemeMode _mode = ThemeMode.system;
  bool _bioAvail = false;
  bool _bioEnabled = false;
  List<BiometricType> _bioTypes = const [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _mode = DI.theme.mode;
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    // availability() mengembalikan record (bool, String?, List<BiometricType>)
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
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: selected ? Icon(CupertinoIcons.check_mark_circled_solid, color: Theme.of(context).colorScheme.primary) : null,
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

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final userEmail = await DI.auth.getEmail();
      final userName = await DI.auth.getFullName();
      if (mounted) {
        setState(() {
          email = userEmail;
          fullName = userName;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        Notifier.error('Gagal memuat data profil: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: primaryColor,
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(
                            CupertinoIcons.person_alt,
                            size: 60,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          fullName ?? 'Pengguna',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          email ?? '-',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Pengaturan Akun',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(CupertinoIcons.pencil, color: primaryColor),
                          title: const Text('Edit Profil'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Implementasi edit profil
                            Notifier.info('Fitur akan segera tersedia');
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(CupertinoIcons.lock, color: primaryColor),
                          title: const Text('Ganti Password'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.pushNamed(context, '/change-password'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(CupertinoIcons.lock_rotation, color: primaryColor),
                          title: const Text('Lupa Password (OTP)'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.pushNamed(context, '/forgot'),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Tema',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _themeTile('Ikuti Sistem', ThemeMode.system, CupertinoIcons.gear),
                        const Divider(height: 1),
                        _themeTile('Terang', ThemeMode.light, CupertinoIcons.sun_max),
                        const Divider(height: 1),
                        _themeTile('Gelap', ThemeMode.dark, CupertinoIcons.moon),
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Keamanan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        if (_bioAvail)
                          SwitchListTile.adaptive(
                            title: Text('Gunakan ${_bioLabel()}'),
                            subtitle: const Text('Kunci aplikasi saat dibuka'),
                            value: _bioEnabled,
                            activeColor: Theme.of(context).colorScheme.primary,
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
                          ListTile(
                            leading: Icon(CupertinoIcons.lock, color: Theme.of(context).colorScheme.primary),
                            title: const Text('Biometrik tidak tersedia'),
                            subtitle: const Text('Perangkat tidak mendukung / belum didaftarkan'),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(CupertinoIcons.lock_open, color: Colors.red),
                      title: const Text('Logout', style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Konfirmasi'),
                            content: const Text('Apakah Anda yakin ingin keluar?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          await DI.auth.logout();
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}