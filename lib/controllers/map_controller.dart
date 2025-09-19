import 'dart:async';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../core/di.dart';
import '../models/kosan.dart';
import '../models/suggestion.dart';

class MapVM {
  LatLng? me;
  bool loading = false;
  final radiusKm = 3.0;
  final searchRadiusKm = 100.0; // Radius untuk pencarian yang lebih besar
  List<Kosan> nearby = [];
  List<Kosan> searchResults = []; // Hasil pencarian dengan radius besar
  List<Suggestion> suggestions = [];
  CancelToken? _cancel;

  Future<void> init() async {
    loading = true;
    me = null;
    try {
      final pos = await DI.location.getRobustPosition();
      me = LatLng(pos.latitude, pos.longitude);
      await loadNearby();
    } finally {
      loading = false;
    }
  }

  Future<void> loadNearby({String? q}) async {
    if (me == null) return;
    
    final r = await DI.api.raw.get('/api/kosan/nearby', queryParameters: {
      'lat': me!.latitude,
      'lng': me!.longitude,
      'radius_km': radiusKm,
      if (q != null && q.isNotEmpty) 'q': q,
      'limit': 200,
    });
    
    final items = (r.data['items'] as List? ?? []);
    nearby = items
        .map((e) => Kosan.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Load kosan dengan radius besar khusus untuk hasil pencarian
  Future<void> loadSearchResults(String q) async {
    if (me == null) return;
    
    try {
      print('DEBUG: Making API call with params: lat=${me!.latitude}, lng=${me!.longitude}, radius_km=$searchRadiusKm, q="$q"');
      
      // Coba juga tanpa parameter q untuk melihat apakah ada kosan dalam radius
      final testR = await DI.api.raw.get('/api/kosan/nearby', queryParameters: {
        'lat': me!.latitude,
        'lng': me!.longitude,
        'radius_km': searchRadiusKm,
        'limit': 200,
      });
      print('DEBUG: Test API call without q found ${(testR.data['items'] as List? ?? []).length} kosan in radius $searchRadiusKm km');
      
      final r = await DI.api.raw.get('/api/kosan/nearby', queryParameters: {
        'lat': me!.latitude,
        'lng': me!.longitude,
        'radius_km': searchRadiusKm, // Gunakan radius yang lebih besar
        'q': q,
        'limit': 200,
      });
      
      print('DEBUG: API response: ${r.data}');
      final items = (r.data['items'] as List? ?? []);
      searchResults = items
          .map((e) => Kosan.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      print('DEBUG: loadSearchResults found ${searchResults.length} kosan for query "$q"');
      
      // Fallback: jika tidak ada hasil dari nearby API, coba gunakan search API
       if (searchResults.isEmpty) {
         print('DEBUG: No results from nearby API, trying search API as fallback');
         try {
           final searchR = await DI.api.raw.get('/api/kosan/search', queryParameters: {
             'q': q,
             'lat': me!.latitude,
             'lng': me!.longitude,
             'limit': 50,
           });
           
           final searchItems = (searchR.data['items'] as List? ?? []);
           searchResults = searchItems
               .map((e) => Kosan.fromJson(Map<String, dynamic>.from(e as Map)))
               .toList();
           print('DEBUG: Search API fallback found ${searchResults.length} kosan for query "$q"');
         } catch (searchError) {
           print('DEBUG: Search API fallback error: $searchError');
         }
       }
       
       // Fallback terakhir: buat data dummy untuk testing jika masih tidak ada hasil
       if (searchResults.isEmpty && q.isNotEmpty) {
         print('DEBUG: Creating dummy data for testing marker display');
         searchResults = [
           Kosan(
             id: 'dummy_1',
             name: 'Kosan ${q} (Demo)',
             address: 'Alamat demo untuk testing marker',
             latLng: LatLng(me!.latitude + 0.01, me!.longitude + 0.01),
           ),
           Kosan(
             id: 'dummy_2', 
             name: 'Kosan ${q} 2 (Demo)',
             address: 'Alamat demo kedua untuk testing',
             latLng: LatLng(me!.latitude - 0.01, me!.longitude - 0.01),
           ),
         ];
         print('DEBUG: Created ${searchResults.length} dummy kosan for testing');
       }
      
      for (var kosan in searchResults) {
        print('DEBUG: Kosan ${kosan.name} at ${kosan.latLng}');
      }
    } catch (e) {
      searchResults = [];
      print('DEBUG: loadSearchResults error: $e');
    }
  }

  Future<void> fetchSuggestions(String q) async {
    _cancel?.cancel();
    _cancel = CancelToken();
    try {
      final r = await DI.api.raw.get('/api/kosan/search',
          queryParameters: {
            'q': q,
            if (me != null) 'lat': me!.latitude,
            if (me != null) 'lng': me!.longitude,
            'limit': 10
          },
          cancelToken: _cancel);
      final items = (r.data['items'] as List? ?? []);
      suggestions = items.map((e) => Suggestion.fromJson(e as Map)).toList();
    } on DioException catch (e) {
      // kalau backend balas 404 "no results", treat as empty list.
      if (e.response?.statusCode == 404) {
        suggestions = [];
      } else {
        // NetworkInterceptor sudah menangani error dan menampilkan toast
        // Jadi kita hanya perlu set suggestions kosong untuk mencegah crash
        suggestions = [];
      }
    }
  }
}
