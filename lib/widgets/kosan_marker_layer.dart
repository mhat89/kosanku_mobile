import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/kosan.dart';

class KosanMarkerLayer extends StatelessWidget {
  final LatLng? me;
  final List<Kosan> kos;
  final void Function(Kosan k)? onNavigate;

  const KosanMarkerLayer({
    super.key,
    required this.me,
    required this.kos,
    this.onNavigate,
  });

  void _showKosanPopup(BuildContext context, Kosan k) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(CupertinoIcons.house_fill,
                      color: CupertinoColors.activeBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      k.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minSize: 0,
                    child: const Icon(CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.systemGrey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(CupertinoIcons.placemark,
                      size: 18, color: CupertinoColors.systemGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      k.address,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        Navigator.pop(context);
                        onNavigate?.call(k);
                      },
                      child: const Text('Rute'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (me != null)
        Marker(
          point: me!,
          width: 40,
          height: 40,
          child: const Icon(
            CupertinoIcons.location_solid,
            color: CupertinoColors.activeBlue,
            size: 32,
          ),
        ),
      ...kos.map(
            (k) => Marker(
          point: k.latLng,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showKosanPopup(context, k),
            child: const Icon(
              CupertinoIcons.house_fill,
              color: CupertinoColors.systemRed,
              size: 36,
            ),
          ),
        ),
      ),
    ];
    return MarkerLayer(markers: markers);
  }
}
