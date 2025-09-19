import 'dart:math';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_compass/flutter_map_compass.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import '../core/di.dart';
import '../models/kosan.dart';
import '../views/detail/detail_screen.dart';
import 'user_tooltip_bubble.dart';

class LeafletMapView extends StatefulWidget {
  final LatLng? myLocation;
  final List<Kosan> kosan;
  final List<Kosan> searchResults; // Hasil pencarian dengan radius besar
  final MapController mapController;

  /// Garis rute (opsional)
  final List<LatLng> route;

  /// Info rute opsional untuk ditampilkan
  final double? routeDistanceM;
  final int? routeDurationS;

  /// Callback opsional ketika user memilih aksi "Detail / Arahkan" (tidak auto navigasi)
  final ValueChanged<Kosan>? onKosanTap;
  final VoidCallback? onMapReady;
  final double? headingDeg; // heading (derajat) dari kompas
  final bool compassOn; // apakah kompas aktif

  const LeafletMapView({
    super.key,
    required this.mapController,
    this.myLocation,
    this.kosan = const [],
    this.searchResults = const [],
    this.route = const [],
    this.routeDistanceM,
    this.routeDurationS,
    this.onKosanTap,
    this.onMapReady, // <— di konstruktor
    this.headingDeg,
    this.compassOn = false,
  });

  @override
  State<LeafletMapView> createState() => _LeafletMapViewState();
}

class _LeafletMapViewState extends State<LeafletMapView> {
  // 👉 [BARU] Menyimpan kosan yang sedang dipilih untuk popup
  Kosan? _selectedKosan;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final userName = await DI.auth.getFullName();
      debugPrint('Loaded user name: $userName');
      if (mounted && userName != null) {
        setState(() {
          _userName = userName;
        });
        debugPrint('User name set to: $_userName');
      }
    } catch (e) {
      // Jika gagal mengambil nama user, biarkan kosong
      debugPrint('Failed to load user name: $e');
    }
  }

  @override
  void didUpdateWidget(covariant LeafletMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Center ke lokasi user ketika ready pertama kali
    /*if (oldWidget.myLocation == null && widget.myLocation != null) {
      widget.mapController.move(widget.myLocation!, 16);
      BotToast.showText(text: 'GPS locked');
    }*/

    // Reset rotasi peta ke 0 ketika kompas dimatikan
    if (oldWidget.compassOn && !widget.compassOn) {
      widget.mapController.rotate(0);
    }

    // Update rotasi peta ketika headingDeg berubah dengan animasi smooth
    if (widget.compassOn && 
        widget.headingDeg != null && 
        oldWidget.headingDeg != widget.headingDeg) {
      // Gunakan animasi manual untuk rotasi yang lebih halus
      widget.mapController.rotate(-widget.headingDeg!);
    }

    // Update info rute & fit kamera jika polyline berubah
    if (widget.route.isNotEmpty &&
        (oldWidget.routeDistanceM != widget.routeDistanceM ||
            oldWidget.routeDurationS != widget.routeDurationS)) {
      final d = widget.routeDistanceM ?? 0.0;
      final t = widget.routeDurationS ?? 0;
      final min = (t / 60).ceil();
      BotToast.showText(
          text:
              'Rute: ${(d / 1000).toStringAsFixed(2)} km • ±$min menit (perkiraan)');
      _fitBoundsForRoute();
    }
  }

  // 👉 [BARU] Fit kamera ke polyline (API flutter_map v6)
  void _fitBoundsForRoute() {
    if (widget.route.length < 2) return;
    final latitudes = widget.route.map((e) => e.latitude).toList()..sort();
    final longitudes = widget.route.map((e) => e.longitude).toList()..sort();
    final sw = LatLng(latitudes.first, longitudes.first);
    final ne = LatLng(latitudes.last, longitudes.last);

    widget.mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(sw, ne),
        padding: const EdgeInsets.all(36),
      ),
    );
  }

  // Rotasi peta sekarang ditangani langsung di MapOptions

  // 👉 [BARU] Kosan terdekat dari titik tap (threshold meter)
  Kosan? _nearestKosan(LatLng tap, {double thresholdMeters = 30}) {
    if (widget.kosan.isEmpty) return null;
    const dist = Distance();
    Kosan? best;
    double bestD = double.infinity;
    for (final k in widget.kosan) {
      final d = dist(tap, k.latLng); // meter
      if (d < bestD) {
        bestD = d;
        best = k;
      }
    }
    if (bestD <= thresholdMeters) return best;
    return null;
  }

  void _openPopupFor(Kosan k) {
    setState(() => _selectedKosan = k);
  }

  void _closePopup() {
    if (_selectedKosan != null) {
      setState(() => _selectedKosan = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.myLocation ?? const LatLng(-6.2, 106.816666);
    
    double? _distanceFromMeTo(LatLng dst) {
      if (widget.myLocation == null) return null;
      const d = Distance();
      return d(widget.myLocation!, dst);
    }

    return Stack(
      children: [
        // Gunakan FlutterMap dengan MapCompass untuk rotasi native
        FlutterMap(
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              // Rotasi peta berdasarkan heading compass
              initialRotation: widget.compassOn && widget.headingDeg != null 
                  ? -widget.headingDeg! 
                  : 0,

            // 👉 [BARU] Tap di peta → pilih kosan terdekat (jika ada) → tampilkan popup
            onTap: (tapPos, tapLatLng) {
              final k = _nearestKosan(tapLatLng, thresholdMeters: 30);
              if (k != null) {
                _openPopupFor(k);
              } else {
                _closePopup();
              }
            },

            // (opsional) tutup popup saat drag/zoom
            onMapEvent: (evt) {
              if (evt is MapEventMoveStart || evt is MapEventFlingAnimation) {
                _closePopup();
              }
            },

            onMapReady: () {
              // Tandai map sudah siap; setelah ini baru boleh panggil fitBounds/animate
              if (widget.onMapReady != null) widget.onMapReady!();
            },
          ),
          children: [
            // Tile Leaflet (OSM)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.kosanku_mobile',
              retinaMode: true,
              maxZoom: 19,
            ),

            // Polyline rute (opsional)
            if (widget.route.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.route,
                    strokeWidth: 5,
                    color: const Color(0xFF007AFF),
                  ),
                ],
              ),

            // Marker lokasi saya; rotasi ikon mengikuti kompas jika aktif
            if (widget.myLocation != null)
              MarkerLayer(markers: [
                Marker(
                  point: widget.myLocation!,
                  width: 42,
                  height: 42,
                  child: Transform.rotate(
                    angle: (widget.compassOn
                        ? ((widget.headingDeg ?? 0) * 3.1415926535 / 180.0)
                        : 0),
                    child: UserTooltipBubble(
                      userName: _userName.isNotEmpty ? _userName : 'Pengguna',
                      showTooltip: true,
                      child: SvgPicture.asset(
                        'assets/markers/person.svg',
                        width: 34,
                        height: 34,
                      ),
                    ),
                  ),
                ),
              ]),

            // Marker kosan nearby (tap pada ikon juga buka popup yang sama)
            MarkerLayer(
              markers: widget.kosan
                  .map(
                    (k) => Marker(
                        point: k.latLng,
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _openPopupFor(k),
                          child: Image.asset(
                            'assets/markers/kosan.png',
                            width: 36,
                            height: 36,
                            errorBuilder: (_, __, ___) => const Icon(
                              CupertinoIcons.house,
                              color: CupertinoColors.black,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                  )
                  .toList(),
            ),

            // Marker kosan dari hasil pencarian (dengan warna berbeda)
            Builder(
              builder: (context) {
                print('DEBUG: LeafletMapView rendering ${widget.searchResults.length} search result markers');
                return MarkerLayer(
                  markers: widget.searchResults
                      .map(
                        (k) => Marker(
                            point: k.latLng,
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () => _openPopupFor(k),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.house,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      )
                      .toList(),
                );
              },
            ),

            // 👉 [BARU] Popup anchored di koordinat kosan terpilih
            if (_selectedKosan != null)
              Builder(
                builder: (context) {
                  final selectedKosan = _selectedKosan!;
                  return MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedKosan.latLng,
                        width: 260,
                        height: 200,
                        child: _KosanPopupCard(
                          k: selectedKosan,
                          onClose: _closePopup,
                          onDetail: () {
                            _closePopup();
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => DetailScreen(kosan: selectedKosan),
                              ),
                            );
                          },
                          distanceMeters: _distanceFromMeTo(selectedKosan.latLng),
                        ),
                      ),
                    ],
                  );
                },
              ),

            // MapCompass untuk kontrol rotasi
            if (widget.compassOn)
              const MapCompass.cupertino(
                hideIfRotatedNorth: false,
              ),
          ],
        ), // FlutterMap

        // (opsional) Search bar dsb bisa dipasang di sini
      ],
    );
  }
}

// 👉 [BARU] Card popup kecil (gambar + nama). Tidak melakukan navigasi sendiri.
class _KosanPopupCard extends StatelessWidget {
  final Kosan k;
  final VoidCallback onClose;
  final VoidCallback? onDetail;
  final double? distanceMeters; // opsional jarak untuk ditampilkan

  const _KosanPopupCard({
    required this.k,
    required this.onClose,
    this.onDetail,
    this.distanceMeters,
  });

  @override
  Widget build(BuildContext context) {
    Widget _imgFallback() => Container(
          color: const Color(0xFFEFEFEF),
          alignment: Alignment.center,
          child: const Icon(CupertinoIcons.photo,
              size: 28, color: CupertinoColors.systemGrey),
        );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 220,
          height: 170,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Carousel gambar (atau single fallback)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: (k.imageUrls.isNotEmpty)
                        ? PageView.builder(
                            itemCount: k.imageUrls.length,
                            itemBuilder: (_, i) => Image.network(
                              k.imageUrls[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imgFallback(),
                            ),
                          )
                        : (k.imageUrl != null && k.imageUrl!.isNotEmpty)
                            ? Image.network(k.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imgFallback())
                            : _imgFallback(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onDetail,
                          child: Text(
                            k.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onDetail,
                        child: Image.asset(
                          'assets/markers/kosan.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                if (distanceMeters != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                    child: Text(
                      '${(distanceMeters! / 1000).toStringAsFixed(2)} km dari posisi Anda',
                      style: const TextStyle(
                          fontSize: 11, color: CupertinoColors.systemGrey),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Tombol tutup (X)
        Positioned(
          right: -6,
          top: -6,
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: CupertinoColors.systemGrey2,
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.clear_thick,
                  size: 14, color: CupertinoColors.white),
            ),
          ),
        ),
      ],
    );
  }
}
