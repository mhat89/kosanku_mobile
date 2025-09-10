import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef OnSearch = Future<void> Function(String query);
typedef OnChanged = Future<void> Function(String text);

class KosanSearchBar extends StatefulWidget {
  final OnSearch onSubmit;
  final OnChanged onChanged;
  const KosanSearchBar({super.key, required this.onSubmit, required this.onChanged});

  @override
  State<KosanSearchBar> createState() => _KosanSearchBarState();
}

class _KosanSearchBarState extends State<KosanSearchBar> {
  final ctl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(CupertinoIcons.search),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: ctl,
                decoration: const InputDecoration(
                  hintText: 'Cari kosan / daerah…',
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), () {
                    widget.onChanged(v.trim());
                  });
                },
                onSubmitted: (v) => widget.onSubmit(v.trim()),
              ),
            ),
            GestureDetector(
              onTap: () => widget.onSubmit(ctl.text.trim()),
              child: const Icon(CupertinoIcons.arrow_right_circle_fill),
            ),
          ],
        ),
      ),
    );
  }
}
