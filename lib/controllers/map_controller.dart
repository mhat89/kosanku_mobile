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
  List<Kosan> nearby = [];
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
    nearby = items.map((e) => Kosan.fromJson(e as Map)).toList();
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
        rethrow;
      }
    }
  }
}
