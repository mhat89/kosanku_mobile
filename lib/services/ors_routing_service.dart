import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';

/// OpenRouteService: gratis 2.500 request/hari. Perlu API key.
/// Daftar: https://openrouteservice.org/dev/#/signup
class ORSRoutingService implements IRoutingService {
  final Dio _dio;
  final String apiKey;
  ORSRoutingService(this._dio, this.apiKey);

  @override
  Future<RouteResult> getRoute(LatLng from, LatLng to, {String mode = 'driving'}) async {
    // mode ORS: driving-car | driving-hgv | cycling-regular | foot-walking | foot-hiking, dst.
    final profile = _mapMode(mode);
    final url = 'https://api.openrouteservice.org/v2/directions/$profile';
    final res = await _dio.get(url, queryParameters: {
      'api_key': apiKey,
      'start': '${from.longitude},${from.latitude}',
      'end': '${to.longitude},${to.latitude}',
    });

    final data = res.data as Map;
    if (data['features'] == null || (data['features'] as List).isEmpty) {
      throw Exception('ORS: rute tidak ditemukan');
    }

    final feature = (data['features'] as List).first as Map;
    final props = feature['properties'] as Map;
    final summary = props['summary'] as Map;
    final geom = feature['geometry'] as Map;

    final coords = (geom['coordinates'] as List)
        .cast<List>()
        .map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    return RouteResult(
      points: coords,
      distanceMeters: (summary['distance'] as num).toDouble(),
      durationSeconds: (summary['duration'] as num).toDouble(),
    );
  }

  String _mapMode(String mode) {
    switch (mode) {
      case 'walking':
        return 'foot-walking';
      case 'cycling':
        return 'cycling-regular';
      default:
        return 'driving-car';
    }
  }
}
