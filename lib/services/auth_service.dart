import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api;
  final FlutterSecureStorage _storage;
  AuthService(this._api, this._storage);

  Future<void> _setToken(String? t) async {
    if (t == null) return;
    await _storage.write(key: 'accessToken', value: t);
    _api.setAuthToken(t); // <<< UPDATE header Authorization secara terpusat
  }

  Future<bool> hasToken() async =>
      (await _storage.read(key: 'accessToken'))?.isNotEmpty == true;

  Future<void> saveEmail(String email) =>
      _storage.write(key: 'userEmail', value: email);
  Future<String?> getEmail() => _storage.read(key: 'userEmail');
  
  Future<String?> getFullName() => _storage.read(key: 'userName');

  Future<void> register(
      String email, String password, String fullName) async {
    await _api.post('/api/auth/register',
        data: {'email': email, 'password': password, 'full_name': fullName});
    await saveEmail(email);
    await _storage.write(key: 'userName', value: fullName);
  }

  Future<void> resendOtp(String email) async =>
      _api.post('/api/auth/resend-otp', data: {'email': email});

  Future<void> verifyOtp(String email, String code) async {
    final r = await _api.post('/api/auth/verify-otp',
        data: {'email': email, 'code': code});
    await _setToken((r.data as Map)['accessToken']?.toString());
    await saveEmail(email);
  }

  Future<void> login(String email, String password) async {
    final r = await _api.post('/api/auth/login',
        data: {'email': email, 'password': password});
    await _setToken((r.data as Map)['accessToken']?.toString());
    await saveEmail(email);
    
    // Simpan nama pengguna jika tersedia dalam respons
    final userData = r.data as Map;
    if (userData.containsKey('user') && userData['user'] is Map) {
      final user = userData['user'] as Map;
      if (user.containsKey('full_name')) {
        await _storage.write(key: 'userName', value: user['full_name']?.toString());
      }
    }
  }

  Future<void> forgotPassword(String email) async =>
      _api.post('/api/auth/forgot-password', data: {'email': email});

  Future<void> verifyForgotOtp(
      String email, String code, String newPass) async {
    await _api.post('/api/auth/verify-forgot-otp', data: {
      'email': email,
      'code': code,
      'password': newPass,
      'password_confirmation': newPass
    });
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } finally {
      await _storage.delete(key: 'accessToken');
      await _storage.delete(key: 'userName');
      _api.setAuthToken(null); // <<< hapus header Authorization
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await _api.post('/api/auth/change-password', data: {
      'old_password': oldPassword,
      'password': newPassword,
      'password_confirmation': newPasswordConfirm,
    });
  }

}
