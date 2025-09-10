import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<void> _ensure() async {
    final on = await Geolocator.isLocationServiceEnabled();
    if (!on) {
      await Geolocator.openLocationSettings();
      await Future.delayed(const Duration(seconds: 2));
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location service OFF');
      }
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }
  }

  Future<Position> getRobustPosition() async {
    await _ensure();

    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return last;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
    } catch (_) {
      final stream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );
      return await stream.first.timeout(const Duration(seconds: 20));
    }
  }
}
