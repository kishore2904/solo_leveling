import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'daily_quests_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'hydration_dashboard_screen.dart';
import 'add_task_screen.dart';
import 'add_reminder_screen.dart';
import 'reminders_screen.dart';

class MainApp extends StatefulWidget {
  final String playerName;

  const MainApp({super.key, required this.playerName});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeScreenKey, playerName: widget.playerName),
      const DailyQuestsScreen(),
      HydrationDashboardScreen(playerName: widget.playerName),
      const RemindersScreen(),
      ProfileScreen(playerName: widget.playerName),
      const StatsScreen(),
    ];
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Refresh HomeScreen data when switching to it
    if (index == 0) {
      _homeScreenKey.currentState?.refreshPlayerLevel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show modal to choose between Quest or Reminder
          showModalBottomSheet(
            context: context,
            backgroundColor: const Color(0xFF121B3A),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      '➕ What do you want to add?',
                      style: TextStyle(
                        color: Color(0xFF00D9FF),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTaskScreen(),
                          ),
                        );
                        
                        if (result == true && _selectedIndex == 1) {
                          setState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF).withOpacity(0.2),
                        side: const BorderSide(
                          color: Color(0xFF00D9FF),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '🎯 Daily Quest',
                        style: TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddReminderScreen(),
                          ),
                        );
                        
                        if (result == true && _selectedIndex == 3) {
                          setState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF).withOpacity(0.2),
                        side: const BorderSide(
                          color: Color(0xFF00D9FF),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '🔔 Reminder',
                        style: TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF00D9FF),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.add,
          color: Color(0xFF0A0E27),
          size: 28,
        ),
      ),
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
            icon: Icon(Icons.notifications),
            label: 'Reminders',
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
