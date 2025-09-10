import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeController extends ChangeNotifier {
  final FlutterSecureStorage storage;
  static const _key = 'appThemeMode'; // 'light' | 'dark' | 'system'
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  ThemeController(this.storage);

  Future<void> load() async {
    final v = await storage.read(key: _key);
    switch (v) {
      case 'light': _mode = ThemeMode.light; break;
      case 'dark': _mode = ThemeMode.dark; break;
      default: _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    await storage.write(
      key: _key,
      value: m == ThemeMode.light ? 'light' : m == ThemeMode.dark ? 'dark' : 'system',
    );
    notifyListeners();
  }
}
