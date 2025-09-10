import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service biometrik/credential yang:
/// - Deteksi biometrik (termasuk strong/weak)
/// - Coba biometricOnly:true -> fallback biometricOnly:false
/// - Ekspose error code supaya kelihatan kenapa gagal (ColorOS sering "notAvailable"/"notEnrolled")
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage;

  static const _keyEnabled = 'biometricEnabled';

  BiometricService(this._storage);

  Future<bool> isEnabled() async =>
      (await _storage.read(key: _keyEnabled)) == '1';

  Future<void> setEnabled(bool v) async =>
      _storage.write(key: _keyEnabled, value: v ? '1' : '0');

  /// Hentikan sesi autentikasi yang masih aktif sebelum fallback
  Future<void> stop() async {
    try { await _auth.stopAuthentication(); } catch (_) {}
  }

  /// Cek dukungan (toleran). Return (ok, reason, types)
  Future<(bool ok, String? reason, List<BiometricType> types)> availability() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final types = await _auth.getAvailableBiometrics();

      final hasBio = types.any((t) =>
      t == BiometricType.fingerprint ||
          t == BiometricType.face ||
          t == BiometricType.iris ||
          t == BiometricType.strong ||
          t == BiometricType.weak);

      if (!supported) return (false, 'notSupported', <BiometricType>[]);
      if (hasBio && canCheck) return (true, null, types);

      // Device supported tapi tidak expose daftar biometrik → izinkan fallback credential
      return (true, 'SUPPORTED_NO_BIO', types);
    } on PlatformException catch (e) {
      return (false, e.code.isNotEmpty ? e.code : 'error', <BiometricType>[]);
    }
  }

  /// Autentikasi. Balikkan (ok, code, message)
  Future<(bool ok, String? code, String? message)> _authWith({
    required bool biometricOnly,
    required String reason,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: false,            // biasanya lebih stabil di ColorOS/MIUI
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      return (ok, null, null);
    } on PlatformException catch (e) {
      return (false, e.code, e.message);
    }
  }

  /// Coba aktifkan kunci: biometrik → credential; kembalikan (ok, errorHumanReadable)
  Future<(bool ok, String? error)> tryEnable() async {
    final (avail, why, _types) = await availability();
    if (!avail) {
      return (false, 'Perangkat tidak mendukung biometrik ($why)');
    }

    // 1) Kalau ada biometrik "nyata" (why == null), coba biometricOnly:true
    if (why == null) {
      final (okBio, code, msg) = await _authWith(
        biometricOnly: true,
        reason: 'Aktifkan kunci biometrik',
      );
      if (okBio) {
        await setEnabled(true);
        return (true, null);
      }
      // hentikan sesi sebelum fallback
      await stop();

      // Kalau errornya jelas (misal notEnrolled / passcodeNotSet), kita teruskan agar user tahu.
      // Dokumentasi error code umum local_auth:
      //  - notAvailable, notEnrolled, passcodeNotSet, lockedOut, permanentlyLockedOut, notInteractive
      if (code == 'notEnrolled') {
        return (false, 'Belum ada biometrik yang didaftarkan di perangkat');
      }
      if (code == 'passcodeNotSet') {
        return (false, 'Kunci layar perangkat belum diaktifkan (PIN/Pola/Sandi)');
      }
      // Lainnya: lanjut fallback credential
    }

    // 2) Fallback ke Device Credential (PIN/Pola/Sandi)
    final (okCred, code2, msg2) = await _authWith(
      biometricOnly: false,
      reason: 'Aktifkan kunci perangkat',
    );
    if (okCred) {
      await setEnabled(true);
      return (true, null);
    }

    // Susun pesan yang lebih informatif untuk UI
    final friendly = _humanize(code2, msg2);
    return (false, friendly);
  }

  String _humanize(String? code, String? msg) {
    switch (code) {
      case 'notAvailable':
        return 'Biometrik tidak tersedia di perangkat';
      case 'notEnrolled':
        return 'Belum ada biometrik yang didaftarkan di perangkat';
      case 'passcodeNotSet':
        return 'Kunci layar perangkat belum diaktifkan (PIN/Pola/Sandi)';
      case 'lockedOut':
        return 'Sensor terkunci sementara. Coba lagi beberapa menit';
      case 'permanentlyLockedOut':
        return 'Sensor terkunci permanen sampai kunci perangkat dibuka';
      case 'notInteractive':
        return 'Tidak dapat menampilkan prompt. Pastikan aplikasi berada di depan';
      default:
        return msg ?? 'Aktivasi dibatalkan atau tidak didukung';
    }
  }

  /// Dipanggil saat membuka aplikasi (gate). true jika lolos (biometrik atau credential)
  Future<bool> gateOpen({String reason = 'Buka Kosanku'}) async {
    final enabled = await isEnabled();
    if (!enabled) return true;

    final (avail, _why, _types) = await availability();
    if (!avail) return false;

    // Coba biometrik dulu
    var (okBio, _c1, _m1) = await _authWith(biometricOnly: true, reason: reason);
    if (okBio) return true;

    await stop();
    // Fallback credential
    var (okCred, _c2, _m2) = await _authWith(biometricOnly: false, reason: reason);
    return okCred;
  }
}
