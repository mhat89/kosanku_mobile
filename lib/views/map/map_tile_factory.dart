import 'package:flutter_map/flutter_map.dart';

class MapTileFactory {
  /// provider: 'osm' | 'maptiler' | 'mapbox'
  // pastikan fungsi bertipe: TileLayer (non-nullable)
  TileLayer build({String provider = 'osm', String? maptilerKey, String? mapboxToken}) {
    switch (provider) {
      case 'maptiler':
      // kalau key kosong, tetap balikin OSM agar tidak null
        if (maptilerKey == null || maptilerKey.isEmpty) {
          return TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.kosanku',
          );
        }
        return TileLayer(
          urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$maptilerKey',
          userAgentPackageName: 'com.example.kosanku',
        );

      case 'mapbox':
        if (mapboxToken == null || mapboxToken.isEmpty) {
          return TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.kosanku',
          );
        }
        return TileLayer(
          urlTemplate:
          'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxToken',
          userAgentPackageName: 'com.example.kosanku',
        );

      case 'osm':
      default:
        return TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.kosanku',
        );
    }
  }
}
