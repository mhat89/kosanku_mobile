import 'dart:math' show pi;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DraggableEtaPanel extends StatefulWidget {
  final Map<String, String> etas;

  const DraggableEtaPanel({super.key, required this.etas});

  @override
  State<DraggableEtaPanel> createState() => _DraggableEtaPanelState();
}

class _DraggableEtaPanelState extends State<DraggableEtaPanel> {
  // Posisi panel
  Offset _position = const Offset(16, 100);
  // Rotasi panel dalam derajat (0, 90, 180, 270)
  double _rotation = 0;
  // Apakah layout horizontal atau vertikal
  bool _isHorizontal = true;

  // Konstanta untuk penyimpanan
  static const String _posXKey = 'eta_panel_pos_x';
  static const String _posYKey = 'eta_panel_pos_y';
  static const String _rotationKey = 'eta_panel_rotation';
  static const String _isHorizontalKey = 'eta_panel_is_horizontal';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Muat pengaturan dari SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _position = Offset(
        prefs.getDouble(_posXKey) ?? 16,
        prefs.getDouble(_posYKey) ?? 100,
      );
      // Muat orientasi panel
      _isHorizontal = prefs.getBool(_isHorizontalKey) ?? true;
      _rotation = _isHorizontal ? 0 : 90;
    });
  }

  // Simpan pengaturan ke SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_posXKey, _position.dx);
    await prefs.setDouble(_posYKey, _position.dy);
    await prefs.setDouble(_rotationKey, _rotation);
    await prefs.setBool(_isHorizontalKey, _isHorizontal);
  }


  // Ubah orientasi panel saat di-tap
  void _rotatePanel() {
    setState(() {
      // Ubah orientasi antara horizontal dan vertikal
      _isHorizontal = !_isHorizontal;
      // Set rotasi sesuai orientasi
      _rotation = _isHorizontal ? 0 : 90;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    // Konversi teks menjadi ikon
    final items = [
      ['Jalan', widget.etas['Jalan'] ?? '-', '🚶‍♂️'],
      ['Sepeda', widget.etas['Sepeda'] ?? '-', '🚲'],
      ['Motor', widget.etas['Motor'] ?? '-', '🏍️'],
      ['Mobil', widget.etas['Mobil'] ?? '-', '🚗'],
    ];

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        // Drag untuk memindahkan panel
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (_) => _saveSettings(),
        // Tap untuk merotasi panel
        onTap: _rotatePanel,
        // Panel tanpa rotasi - hanya layout yang berubah
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xCC000000),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: _isHorizontal ? _buildHorizontalLayout(items) : _buildVerticalLayout(items),
        ),
      ),
    );
  }

  // Layout horizontal (default)
  Widget _buildHorizontalLayout(List<List<String>> items) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items
          .map((e) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                       e[2], // Ikon
                       style: const TextStyle(fontSize: 18),
                       textAlign: TextAlign.center,
                     ),
                    const SizedBox(height: 4),
                    Text(
                      e[1], // Waktu
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // Layout vertikal (icon berbaris vertikal dengan teks di samping)
  Widget _buildVerticalLayout(List<List<String>> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e[2], // Ikon
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      e[1], // Waktu
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}