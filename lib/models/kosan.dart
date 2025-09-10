import 'package:latlong2/latlong.dart';

class Kosan {
  final String id, name, address;
  final double latitude, longitude, distanceKm;
  final int? priceMonth;
  Kosan({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.priceMonth,
  });

  factory Kosan.fromJson(Map j) => Kosan(
    id: j['id'].toString(),
    name: j['name'] ?? '',
    address: j['address'] ?? '',
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0,
    priceMonth: j['price_month'] as int?,
  );

  LatLng get latLng => LatLng(latitude, longitude);
}
