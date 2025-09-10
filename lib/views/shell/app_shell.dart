import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../map/map_screen.dart';
import '../explore/explore_screen.dart';
import '../saved/saved_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final pages = const [
    MapScreen(),
    ExploreScreen(),
    SavedScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.compass), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.bookmark), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
