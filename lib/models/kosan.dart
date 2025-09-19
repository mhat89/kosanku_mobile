import 'package:latlong2/latlong.dart';

class Kosan {
  final String id;
  final String name;
  final String address;
  final LatLng latLng;

  /// Opsional: URL gambar untuk popup
  final String? imageUrl;

  /// Opsional: daftar gambar (untuk carousel)
  final List<String> imageUrls;

  const Kosan({
    required this.id,
    required this.name,
    required this.address,
    required this.latLng,
    this.imageUrl,
    this.imageUrls = const [],
  });

  factory Kosan.fromJson(Map<String, dynamic> j) => Kosan(
        id: j['id']?.toString() ?? '',
        name: j['name'] ?? j['nama'] ?? 'Kosan',
        address: j['address'] ?? j['alamat'] ?? '',
        latLng: LatLng(
          _pickDouble(j, ['lat', 'latitude']) ?? 0.0,
          _pickDouble(j, ['lng', 'longitude']) ?? 0.0,
        ),
        imageUrl: _getPrimaryImageUrl(j),
        imageUrls: _parseImageList(j),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'lat': latLng.latitude,
        'lng': latLng.longitude,
        if (imageUrl != null) 'image_url': imageUrl,
        if (imageUrls.isNotEmpty) 'images': imageUrls,
      };
}

String? _getPrimaryImageUrl(Map<String, dynamic> j) {
  // Prioritas: primary_image dari API Laravel -> image_url -> imageUrl
  final primaryImage = j['primary_image'];
  if (primaryImage != null && primaryImage is Map) {
    final imageUrl = primaryImage['image_url'];
    if (imageUrl is String && imageUrl.isNotEmpty) {
      return imageUrl;
    }
  }
  
  final fallback = j['image_url'] ?? j['imageUrl'];
  if (fallback is String && fallback.isNotEmpty) {
    return fallback;
  }
  
  return null;
}

List<String> _parseImageList(Map<String, dynamic> j) {
  final raw = j['images'] ?? j['image_urls'] ?? j['photos'];
  if (raw is List) {
    return raw
        .whereType<String>()
        .map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  final single = j['image_url'] ?? j['imageUrl'];
  if (single is String && single.isNotEmpty) return [single];
  return const [];
}

double? _pickDouble(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v == null) continue;
    if (v is num) return v.toDouble();
    if (v is String && v.trim().isNotEmpty) {
      final p = double.tryParse(v);
      if (p != null) return p;
    }
  }
  return null;
}
