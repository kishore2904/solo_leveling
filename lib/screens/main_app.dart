import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'daily_quests_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'hydration_dashboard_screen.dart';

class MainApp extends StatefulWidget {
  final String playerName;

  const MainApp({super.key, required this.playerName});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(playerName: widget.playerName),
      const DailyQuestsScreen(),
      HydrationDashboardScreen(playerName: widget.playerName),
      ProfileScreen(playerName: widget.playerName),
      const StatsScreen(),
    ];
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1a1a2e),
        selectedItemColor: const Color(0xFF00D9FF),
        unselectedItemColor: Colors.white54,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Quests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Hydration',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
