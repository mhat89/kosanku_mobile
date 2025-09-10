import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/suggestion.dart';

class SuggestionList extends StatelessWidget {
  final List<Suggestion> items;
  final void Function(Suggestion) onTap;
  const SuggestionList({super.key, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 220,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final s = items[i];
          return ListTile(
            leading: const Icon(CupertinoIcons.house),
            title: Text(s.name),
            subtitle: Text(s.address, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => onTap(s),
          );
        },
      ),
    );
  }
}
