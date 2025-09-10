import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

abstract class IRoutingService {
  /// mode: driving | walking | cycling (disesuaikan provider)
  Future<RouteResult> getRoute(LatLng from, LatLng to, {String mode = 'driving'});
}
