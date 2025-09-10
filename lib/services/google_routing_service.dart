import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';

/// Google Directions API (butuh billing + API key; free credit $200/bulan).
/// Console: https://console.cloud.google.com/
class GoogleRoutingService implements IRoutingService {
  final Dio _dio;
  final String apiKey;
  GoogleRoutingService(this._dio, this.apiKey);

  @override
  Future<RouteResult> getRoute(LatLng from, LatLng to, {String mode = 'driving'}) async {
    final url = 'https://maps.googleapis.com/maps/api/directions/json';
    final res = await _dio.get(url, queryParameters: {
      'origin': '${from.latitude},${from.longitude}',
      'destination': '${to.latitude},${to.longitude}',
      'mode': mode, // driving | walking | bicycling
      'key': apiKey,
    });

    final data = res.data as Map;
    if (data['status'] != 'OK') {
      throw Exception('Google: ${data['status']}');
    }
    final route = (data['routes'] as List).first as Map;
    final leg = (route['legs'] as List).first as Map;
    final distance = (leg['distance'] as Map)['value'] as num; // meters
    final duration = (leg['duration'] as Map)['value'] as num; // seconds
    final encoded = (route['overview_polyline'] as Map)['points'] as String;

    final coords = _decodePolyline(encoded);
    return RouteResult(
      points: coords,
      distanceMeters: distance.toDouble(),
      durationSeconds: duration.toDouble(),
    );
  }

  // Google polyline decoder
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }
}
