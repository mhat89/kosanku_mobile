import 'package:latlong2/latlong.dart';

class Suggestion {
  final String id, name, address;
  final double latitude, longitude;
  final int? priceMonth;
  Suggestion({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.priceMonth,
  });

  factory Suggestion.fromJson(Map j) => Suggestion(
    id: j['id'].toString(),
    name: j['name'] ?? '',
    address: j['address'] ?? '',
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    priceMonth: j['price_month'] as int?,
  );

  LatLng get latLng => LatLng(latitude, longitude);
}
