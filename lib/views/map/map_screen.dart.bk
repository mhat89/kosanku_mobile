import 'dart:async';
import 'dart:math' show pi, atan2, cos, sin;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator; // loader saja
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/map_controller.dart' as vm;
import '../../widgets/search_bar.dart';
import '../../widgets/suggestion_list.dart';
import '../../widgets/kosan_marker_layer.dart';
import '../../core/di.dart';
import '../../ui/notifier.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final map = MapController();
  final m = vm.MapVM();

  bool showSuggest = false;

  // live position & nav state
  StreamSubscription<Position>? _posSub;
  LatLng? _current;              // posisi user live
  LatLng? _destination;          // tujuan kosan
  List<LatLng> _route = [];      // polyline dari provider
  double _bearing = 0;           // arah panah user
  double? _routeDistanceM;       // info jarak
  double? _routeDurationS;       // info waktu

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => m.loading = true);
    try {
      await m.init();
      _current = m.me;
      if (_current != null) map.move(_current!, 15);
      _startTracking();
    } catch (e) {
      m.me ??= const LatLng(-6.2, 106.816666);
      Notifier.error('Gagal mendapatkan lokasi: $e');
    } finally {
      if (mounted) setState(() => m.loading = false);
    }
  }

  void _startTracking() {
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen((pos) {
      final next = LatLng(pos.latitude, pos.longitude);
      if (_current != null) _bearing = _calcBearing(_current!, next);
      _current = next;

      // (opsional) jika ingin re-route otomatis saat menyimpang,
      // bisa deteksi deviasi dari polyline & panggil _recalculateRoute().

      if (mounted) setState(() {});
    });
  }

  double _calcBearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * pi / 180.0;
    final lat2 = b.latitude * pi / 180.0;
    final dLon = (b.longitude - a.longitude) * pi / 180.0;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final brng = atan2(y, x) * 180.0 / pi;
    return (brng + 360.0) % 360.0;
  }

  Future<void> _navigateTo(LatLng dest, {String mode = 'driving'}) async {
    if (_current == null) {
      Notifier.warn('Menunggu posisi GPS…');
      return;
    }
    _destination = dest;

    try {
      Notifier.info('Menghitung rute…');
      final result = await DI.routing.getRoute(_current!, _destination!, mode: mode);
      _route = result.points;
      _routeDistanceM = result.distanceMeters;
      _routeDurationS = result.durationSeconds;

      // tampilkan info
      final km = (_routeDistanceM! / 1000.0);
      final mins = (_routeDurationS! / 60.0);
      Notifier.bannerTop(
        'Rute siap • ${km.toStringAsFixed(2)} km • ${mins.toStringAsFixed(0)} min',
        style: BannerStyle.success,
      );

      // pindah kamera ke posisi user atau bisa juga fit bounds polyline
      map.move(_current!, 15);
      if (mounted) setState(() {});
    } catch (e) {
      Notifier.error('Gagal ambil rute: $e');
    }
  }

  void _stopNavigation() {
    _destination = null;
    _route.clear();
    _routeDistanceM = null;
    _routeDurationS = null;
    if (mounted) setState(() {});
    Notifier.info('Rute dibatalkan');
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = _current ?? m.me ?? const LatLng(-6.2, 106.816666);

    return Stack(
      children: [
        FlutterMap(
          mapController: map,
          options: MapOptions(
            initialCenter: me,
            initialZoom: 13,
          ),
          children: [
            // Ganti style peta dengan provider lain jika mau
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.kosanku',
            ),

            // Polyline rute dari provider
            if (_route.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _route,
                    strokeWidth: 5,
                    color: const Color(0xFF0A84FF), // Cupertino activeBlue
                  ),
                ],
              ),

            // Marker user (bearing)
            MarkerLayer(markers: [
              Marker(
                point: me,
                width: 44,
                height: 44,
                child: Transform.rotate(
                  angle: _bearing * pi / 180.0,
                  child: const Icon(
                    CupertinoIcons.location_north_fill,
                    color: CupertinoColors.activeBlue,
                    size: 36,
                  ),
                ),
              ),
            ]),

            // Marker kos + popup "Rute"
            KosanMarkerLayer(
              me: _current,
              kos: m.nearby,
              onNavigate: (k) => _navigateTo(k.latLng),
            ),
          ],
        ),

        // Search + suggestions
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12, right: 12,
          child: Column(
            children: [
              KosanSearchBar(
                onChanged: (t) async {
                  if (t.isEmpty) {
                    setState(() => showSuggest = false);
                    return;
                  }
                  await m.fetchSuggestions(t);
                  if (mounted) {
                    setState(() => showSuggest = m.suggestions.isNotEmpty);
                  }
                },
                onSubmit: (q) async {
                  await m.loadNearby(q: q);
                  if (mounted) setState(() => showSuggest = false);
                },
              ),
              if (showSuggest)
                SuggestionList(
                  items: m.suggestions,
                  onTap: (s) {
                    map.move(s.latLng, 16);
                    _navigateTo(s.latLng);
                    setState(() => showSuggest = false);
                  },
                ),
            ],
          ),
        ),

        if (m.loading)
          const Align(
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          ),

        // Tombol kanan bawah
        Positioned(
          right: 16,
          bottom: 86,
          child: Column(
            children: [
              // Pusatkan kamera
              CupertinoButton.filled(
                padding: const EdgeInsets.all(10),
                borderRadius: BorderRadius.circular(24),
                child: const Icon(CupertinoIcons.location),
                onPressed: () {
                  if (_current != null) map.move(_current!, 16);
                },
              ),
              const SizedBox(height: 10),
              // Batal rute
              if (_destination != null)
                CupertinoButton(
                  padding: const EdgeInsets.all(10),
                  color: CupertinoColors.systemGrey,
                  borderRadius: BorderRadius.circular(24),
                  child: const Icon(CupertinoIcons.clear),
                  onPressed: _stopNavigation,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
