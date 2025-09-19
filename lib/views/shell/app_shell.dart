import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../map/map_screen.dart';
import '../explore/explore_screen.dart';
import '../saved/saved_screen.dart';
import '../profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final pages = const [
    MapScreen(),
    ExploreScreen(),
    SavedScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.blue,
        buttonBackgroundColor: Colors.blue,
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        index: _selectedIndex,
        items: const [
          Icon(CupertinoIcons.map, size: 30, color: Colors.white),
          Icon(CupertinoIcons.compass, size: 30, color: Colors.white),
          Icon(CupertinoIcons.bookmark, size: 30, color: Colors.white),
          Icon(CupertinoIcons.person, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
