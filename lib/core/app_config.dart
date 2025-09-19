import 'dart:io';

class AppConfig {
  static const String scheme =
      String.fromEnvironment('API_SCHEME', defaultValue: 'http');

  static String get host {
    const h = String.fromEnvironment('API_HOST', defaultValue: '');
    if (h.isNotEmpty) return h;
    //return Platform.isAndroid ? '192.168.100.132' : '127.0.0.1';
    return Platform.isAndroid ? '10.93.242.254:' : '127.0.0.1';
  }

  static const String port =
      String.fromEnvironment('API_PORT', defaultValue: '8000');

  static String get baseUrl => '$scheme://$host:$port';
}
