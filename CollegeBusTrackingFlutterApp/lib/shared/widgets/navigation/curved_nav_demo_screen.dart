import 'package:flutter/material.dart';
import 'curved_bottom_nav_bar.dart';

class CurvedNavDemoScreen extends StatefulWidget {
  const CurvedNavDemoScreen({super.key});

  @override
  State<CurvedNavDemoScreen> createState() => _CurvedNavDemoScreenState();
}

class _CurvedNavDemoScreenState extends State<CurvedNavDemoScreen> {
  int _currentIndex = 0;

  final List<CurvedBottomNavIcon> _navItems = [
    CurvedBottomNavIcon(icon: Icons.people_outline, label: 'Community'),
    CurvedBottomNavIcon(icon: Icons.search, label: 'Explore'),
    CurvedBottomNavIcon(icon: Icons.fitness_center, label: 'Movement'),
    CurvedBottomNavIcon(icon: Icons.bookmark_border, label: 'Plan'),
    CurvedBottomNavIcon(icon: Icons.person_outline, label: 'Mine'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF6366F1,
      ), // Background color from the design
      appBar: AppBar(
        title: const Text(
          'Design Showcase',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selected Tab: ${_navItems[_currentIndex].label}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.touch_app, color: Colors.white70, size: 50),
          ],
        ),
      ),
      bottomNavigationBar: CurvedBottomNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
