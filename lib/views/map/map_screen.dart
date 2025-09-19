import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../models/kosan.dart';
import '../../models/suggestion.dart';
import '../../controllers/map_controller.dart';
// Leaflet view kamu sendiri:
import '../../widgets/leaflet_map_view.dart';
import '../../widgets/draggable_eta_panel.dart';
import '../../core/di.dart';
import '../detail/detail_screen.dart';

/// Halaman peta utama.
/// - Ada tombol GPS untuk re-center peta ke posisi user.
/// - Tetap kompatibel dengan marker kosan & rute jika tersedia.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _Debouncer {
  _Debouncer(this.delay);
  final Duration delay;
  Timer? _t;
  void run(void Function() fn) {
    _t?.cancel();
    _t = Timer(delay, fn);
  }

  void cancel() => _t?.cancel();
}

class _MapScreenState extends State<MapScreen> {
  // Controller peta (flutter_map v6.1.0)
  final MapController _map = MapController();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _mapReady = false; // flag dari onMapReady

  // MapVM instance
  final MapVM _vm = MapVM();

  // Debouncer untuk search
  final _Debouncer _debouncer = _Debouncer(const Duration(milliseconds: 500));

  // State untuk suggestion dropdown
  bool _showSuggestions = false;
  bool _isSearching = false;

  // Posisi saya
  LatLng? _me;

  // Data kosan & rute (opsional, tetap aman walau null/empty)
  List<LatLng> _route = [];
  double? _routeDistanceM;
  int? _routeDurationS;
  LatLng? _destination; // tujuan terkini
  Map<String, String> _etas = const {};
  StreamSubscription<Position>? _posSub; // live tracking
  DateTime? _lastOffRouteAt;
  bool _tracking = false;
  bool _compassOn = false;
  double _headingDeg = 0.0;

  // ========================
  // Lifecycle
  // ========================
  @override
  void initState() {
    super.initState();
    _initLocationSafely();
    _vm.init();
    _setupSearchListener();
    _listenCompass();
  }

  // Wrapper untuk _initLocation() yang menangani error dengan aman
  Future<void> _initLocationSafely() async {
    try {
      await _initLocation();
    } catch (e) {
      BotToast.showText(text: e.toString());
      // Fallback: set lokasi default Jakarta jika gagal mendapatkan lokasi user
      _me = const LatLng(-6.2088, 106.8456); // Jakarta
      if (mounted) setState(() {});
    }
  }

  void _setupSearchListener() {
    _searchCtrl.addListener(() {
      final query = _searchCtrl.text.trim();
      if (query.isEmpty) {
        setState(() {
          _showSuggestions = false;
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _isSearching = true;
        _showSuggestions = true;
      });

      // Debounce search request
      _debouncer.run(() async {
        if (mounted && _searchCtrl.text.trim().isNotEmpty) {
          await _vm.fetchSuggestions(_searchCtrl.text.trim());
          if (mounted) {
            setState(() {
              _isSearching = false;
            });
          }
        }
      });
    });
  }

  // Ambil lokasi awal + permission
  Future<void> _initLocation() async {
    try {
      // Cek apakah service lokasi aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Service lokasi tidak aktif. Silakan aktifkan GPS.');
      }

      // cek & minta izin
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak. Silakan berikan izin lokasi di pengaturan.');
      }

      // Coba ambil last known position dulu untuk performa yang lebih baik
      Position? pos = await Geolocator.getLastKnownPosition();
      
      // Jika tidak ada last known position atau terlalu lama, ambil posisi terbaru
      if (pos == null || DateTime.now().difference(pos.timestamp).inMinutes > 5) {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      }
      
      _me = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() {});

      // pindahkan kamera ke posisi awal user (hanya jika map sudah ready)
      if (_me != null && _mapReady) {
        _map.move(_me!, 16); // zoom awal 16, bisa kamu sesuaikan
      }

      // Load nearby kosan hanya jika belum ada data
      if (_vm.nearby.isEmpty) {
        await _vm.loadNearby();
        if (mounted) setState(() {});
      }
    } catch (e) {
      // Re-throw error agar bisa ditangani oleh caller
      throw Exception('Gagal mendapatkan lokasi: $e');
    }
  }

  // ========================
  // Actions
  // ========================

  /// Re-center peta ke posisi user (dipakai tombol GPS)
  Future<void> _centerOnMe() async {
    try {
      if (_me == null) {
        BotToast.showText(text: 'Mendapatkan lokasi Anda...');
        await _initLocation();
      }
      if (_me != null) {
        // flutter_map v6.1.0 -> pakai move()
        _map.move(_me!, _map.camera.zoom);
        BotToast.showText(text: 'Lokasi ditemukan!');
      } else {
        BotToast.showText(text: 'Lokasi belum tersedia');
      }
    } catch (e) {
      BotToast.showText(text: e.toString());
    }
  }

  /// Ketika marker kosan ditekan (opsional – sesuaikan kebutuhanmu)
  void _onKosanTap(Kosan k) {
    // contoh: tampilkan bottom sheet detail singkat
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(k.name),
        message: Text(k.address),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => DetailScreen(kosan: k),
                ),
              );
            },
            child: const Text('Lihat Detail'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: const Text('OK'),
        ),
      ),
    );
  }

  void _maybeCenterOnce() {
    if (!_mapReady) return;
    if (_me != null) {
      _map.move(_me!, _map.camera.zoom); // aman karena map sudah siap
    }
  }

  /// Handle tap pada suggestion item
  void _onSuggestionTap(Suggestion suggestion) {
    setState(() {
      _showSuggestions = false;
    });
    _searchCtrl.text = suggestion.name;
    _searchFocus.unfocus();

    // Center peta ke lokasi suggestion
    final latLng = LatLng(suggestion.latitude, suggestion.longitude);
    _map.move(latLng, 16);

    // Load kosan dengan radius besar untuk pencarian
    () async {
      try {
        await _vm.loadSearchResults(suggestion.name);
        if (mounted) setState(() {});
      } catch (e) {
        // Ignore error, tidak perlu menampilkan toast untuk ini
      }
    }();

    // Hitung rute dari posisi saya ke kosan terpilih
    () async {
      // Jika lokasi user belum tersedia, coba dapatkan lokasi terlebih dahulu
      if (_me == null) {
        BotToast.showText(text: 'Mendapatkan lokasi Anda...');
        try {
          await _initLocation();
          if (_me == null) {
            BotToast.showText(text: 'Gagal mendapatkan lokasi Anda. Pastikan GPS aktif dan izin lokasi diberikan.');
            return;
          }
        } catch (e) {
          BotToast.showText(text: 'Gagal mendapatkan lokasi: $e');
          return;
        }
      }
      
      setState(() {
        _route = [];
        _routeDistanceM = null;
        _routeDurationS = null;
      });
      
      BotToast.showText(text: 'Menghitung rute...');
      
      try {
        final res = await DI.routing.getRoute(_me!, latLng);
        if (!mounted) return;
        setState(() {
          _route = res.points;
          _routeDistanceM = res.distanceMeters;
          _routeDurationS = res.durationSeconds.toInt();
          _destination = latLng;
          _etas = _computeEtas(res.distanceMeters);
        });
        _startLiveTrack();
        BotToast.showText(text: 'Rute berhasil dibuat!');
      } catch (e) {
        BotToast.showText(text: 'Gagal mendapatkan rute: $e');
      }
    }();
  }

  Map<String, String> _computeEtas(double distanceMeters) {
    // Kecepatan rata-rata (m/s)
    const walk = 1.4; // ~5 km/jam
    const bike = 4.2; // ~15 km/jam
    const motor = 8.3; // ~30 km/jam
    const car = 11.1; // ~40 km/jam
    String fmt(double seconds) {
      final m = (seconds / 60).round();
      if (m < 60) return '${m}m';
      final h = m ~/ 60;
      final rm = m % 60;
      return rm == 0 ? '${h}j' : '${h}j ${rm}m';
    }

    return {
      'Jalan': fmt(distanceMeters / walk),
      'Sepeda': fmt(distanceMeters / bike),
      'Motor': fmt(distanceMeters / motor),
      'Mobil': fmt(distanceMeters / car),
    };
  }

  void _startLiveTrack() {
    if (_tracking) return;
    _tracking = true;
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen((pos) {
      _me = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() {});
      _checkOffRoute();
    });
  }

  void _stopLiveTrack() {
    _posSub?.cancel();
    _posSub = null;
    _tracking = false;
  }

  void _checkOffRoute() {
    if (_me == null || _route.isEmpty) return;
    final d = _distanceToPolylineMeters(_me!, _route);
    const threshold = 40.0; // meter dari jalur
    if (d > threshold) {
      final now = DateTime.now();
      if (_lastOffRouteAt == null ||
          now.difference(_lastOffRouteAt!).inSeconds > 20) {
        _lastOffRouteAt = now;
        HapticFeedback.mediumImpact();
        BotToast.showText(text: 'Anda keluar dari jalur rute');
      }
    }
  }

  double _distanceToPolylineMeters(LatLng p, List<LatLng> line) {
    // pendekatan sederhana: jarak minimum ke titik-titik polyline
    const dist = Distance();
    double best = double.infinity;
    for (final q in line) {
      final d = dist(p, q);
      if (d < best) best = d;
    }
    return best;
  }

  /// Clear suggestions dan hide dropdown
  void _clearSuggestions() {
    setState(() {
      _showSuggestions = false;
      _isSearching = false;
    });
    _searchCtrl.clear();
    _searchFocus.unfocus();
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _stopLiveTrack();
    FlutterCompass.events?.drain();
    super.dispose();
  }

  void _listenCompass() {
    FlutterCompass.events?.listen((event) {
      final hdg = event.heading; // in degrees, may be null
      if (hdg == null) return;
      _headingDeg = hdg;
      if (!_compassOn) return;
      // rotate map to heading while compass mode is ON
      // flutter_map v6: rotate via camera? We can emulate by rotating user marker; for map, keep simple.
      if (mounted) setState(() {});
    });
  }

  // ========================
  // UI
  // ========================
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ===============================
            // Peta Leaflet kamu (widget custom)
            // Pastikan LeafletMapView punya argumen mapController
            // ===============================
            LeafletMapView(
              mapController: _map,
              myLocation: _me,
              kosan: _vm.nearby,
              searchResults: _vm.searchResults,
              route: _route,
              routeDistanceM: _routeDistanceM, // double?
              routeDurationS: _routeDurationS, // int?
              onKosanTap: _onKosanTap,
              onMapReady: () {
                setState(() => _mapReady = true);
                // contoh: kalau mau langsung fit ke lokasi user/route setelah map siap
                _maybeCenterOnce();
              },
              headingDeg: _headingDeg,
              compassOn: _compassOn,
            ),

            // FLOATING SEARCH BAR (atas)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  _SearchBar(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    placeholder: 'Cari kosan / daerah…',
                    onSubmit: (q) async {
                      if (q.trim().isEmpty) return;
                      setState(() => _showSuggestions = false);
                      // 1) panggil API suggestion (punyamu sudah ada)
                      await _vm.fetchSuggestions(q); // kalau kamu pakai MapVM
                      // 2) kalau ada hasil, center ke hasil pertama
                      if (_vm.suggestions.isNotEmpty && _mapReady) {
                        final first = _vm.suggestions.first;
                        final dst = LatLng(first.latitude, first.longitude);
                        _map.move(dst, 16); // zoom 16; boleh ganti
                      } else {
                        // fallback: reload nearby dengan q
                        await _vm.loadNearby(q: q);
                      }
                      if (mounted) setState(() {});
                      _searchFocus.unfocus();
                    },
                    onClear: _clearSuggestions,
                  ),

                  // Suggestion Dropdown
                  if (_showSuggestions && _vm.suggestions.isNotEmpty)
                    _SuggestionDropdown(
                      suggestions: _vm.suggestions,
                      isLoading: _isSearching,
                      onTap: _onSuggestionTap,
                      onClose: () => setState(() => _showSuggestions = false),
                    ),
                ],
              ),
            ),

            // ===============================
            // Tombol GPS (kanan–bawah)
            // ===============================
            Positioned(
              right: 16,
              bottom: 32, // kalau ada bottom bar tinggi, tambah jaraknya
              child: Column(
                children: [
                  _GpsButton(onPressed: _centerOnMe),
                  const SizedBox(height: 10),
                  CupertinoButton(
                    padding: const EdgeInsets.all(10),
                    color: _compassOn
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey,
                    borderRadius: BorderRadius.circular(24),
                    child: const Icon(CupertinoIcons.compass,
                        size: 18, color: CupertinoColors.white),
                    onPressed: () => setState(() => _compassOn = !_compassOn),
                  ),
                ],
              ),
            ),

            if (_routeDistanceM != null)
              DraggableEtaPanel(etas: _etas),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String placeholder;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onClear;

  const _SearchBar({
    required this.controller,
    required this.placeholder,
    required this.onSubmit,
    this.onClear,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC000000), // hitam semi transparan
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          const Icon(CupertinoIcons.search,
              color: CupertinoColors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              focusNode: focusNode,
              placeholder: placeholder,
              placeholderStyle:
                  const TextStyle(color: CupertinoColors.systemGrey),
              style: const TextStyle(color: CupertinoColors.white),
              decoration:
                  const BoxDecoration(color: CupertinoColors.transparent),
              onSubmitted: onSubmit,
            ),
          ),
          const SizedBox(width: 8),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(CupertinoIcons.xmark_circle_fill,
                  color: CupertinoColors.systemGrey2, size: 20),
            ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => onSubmit(controller.text),
            child: const Icon(CupertinoIcons.arrow_right_circle_fill,
                color: CupertinoColors.activeBlue, size: 24),
          ),
        ],
      ),
    );
  }
}

/// Tombol bundar kecil untuk re-center GPS
class _GpsButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GpsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(10),
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: const Icon(
          CupertinoIcons.location_solid,
          size: 22,
          color: CupertinoColors.activeBlue,
        ),
      ),
    );
  }
}

class _EtaPanel extends StatelessWidget {
  final Map<String, String> etas;
  const _EtaPanel({required this.etas});

  @override
  Widget build(BuildContext context) {
    final items = [
      ['Jalan', etas['Jalan'] ?? '-'],
      ['Sepeda', etas['Sepeda'] ?? '-'],
      ['Motor', etas['Motor'] ?? '-'],
      ['Mobil', etas['Mobil'] ?? '-'],
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map((e) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(children: [
                    Text(e[0],
                        style: const TextStyle(
                            color: CupertinoColors.systemGrey, fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(e[1],
                        style: const TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600)),
                  ]),
                ))
            .toList(),
      ),
    );
  }
}

/// Widget untuk menampilkan dropdown suggestion
class _SuggestionDropdown extends StatelessWidget {
  final List<Suggestion> suggestions;
  final bool isLoading;
  final ValueChanged<Suggestion> onTap;
  final VoidCallback onClose;

  const _SuggestionDropdown({
    required this.suggestions,
    required this.isLoading,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC000000), // hitam semi transparan
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header dengan tombol close
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0x33FFFFFF), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.search,
                  color: CupertinoColors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hasil pencarian (${suggestions.length})',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: CupertinoColors.systemGrey2,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

          // List suggestions
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    ),
                  )
                : suggestions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Tidak ada hasil ditemukan',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: suggestions.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0x33FFFFFF),
                        ),
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          return _SuggestionItem(
                            suggestion: suggestion,
                            onTap: () => onTap(suggestion),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Item individual dalam suggestion dropdown
class _SuggestionItem extends StatelessWidget {
  final Suggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionItem({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.house_fill,
                color: CupertinoColors.systemRed,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.name,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suggestion.address,
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey2,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (suggestion.priceMonth != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Rp ${suggestion.priceMonth!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}/bulan',
                        style: const TextStyle(
                          color: CupertinoColors.systemGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey2,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
