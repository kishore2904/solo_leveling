import 'package:flutter/material.dart';

/// Example Navigation Setup for Water Feature
/// 
/// This file demonstrates how to integrate the hydration screens
/// into your main app navigation.

// EXAMPLE 1: Add to main_app.dart routes
class NavigationExample {
  static const String hydrationDashboard = '/hydration/dashboard';
  static const String hydrationStats = '/hydration/stats';
  static const String hydrationAchievements = '/hydration/achievements';
  static const String hydrationSetup = '/hydration/setup';

  // Add these routes to MaterialApp
  static final Map<String, WidgetBuilder> appRoutes = {
    // ... existing routes ...
    hydrationDashboard: (context) {
      // Get playerName from args or provider
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      return HydrationDashboardScreen(playerName: args ?? 'Player');
    },
    hydrationStats: (context) => const HydrationStatsScreen(),
    hydrationAchievements: (context) =>
        const HydrationAchievementsScreen(),
    hydrationSetup: (context) => const HydrationGoalsSetupScreen(),
  };
}

// EXAMPLE 2: Bottom Navigation Integration
class MainNavigationWithHydration extends StatefulWidget {
  const MainNavigationWithHydration({super.key});

  @override
  State<MainNavigationWithHydration> createState() =>
      _MainNavigationWithHydrationState();
}

class _MainNavigationWithHydrationState
    extends State<MainNavigationWithHydration> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    Container(), // Home screen placeholder
    const HydrationDashboardScreen(playerName: 'Player'),
    const HydrationStatsScreen(),
    const HydrationAchievementsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0A0E27),
        selectedItemColor: const Color(0xFF00D9FF),
        unselectedItemColor: const Color(0xFFB0B0B0),
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Hydration',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Achievements',
          ),
        ],
      ),
    );
  }
}

// EXAMPLE 3: Navigation Helper Methods
class HydrationNavigation {
  /// Navigate to dashboard from anywhere
  static void navigateToDashboard(
    BuildContext context,
    String playerName,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            HydrationDashboardScreen(playerName: playerName),
      ),
    );
  }

  /// Navigate to stats
  static void navigateToStats(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HydrationStatsScreen(),
      ),
    );
  }

  /// Navigate to achievements
  static void navigateToAchievements(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HydrationAchievementsScreen(),
      ),
    );
  }

  /// Navigate to setup
  static void navigateToSetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HydrationGoalsSetupScreen(),
      ),
    );
  }

  /// Replace current screen with dashboard
  static void replaceToDashboard(
    BuildContext context,
    String playerName,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            HydrationDashboardScreen(playerName: playerName),
      ),
    );
  }
}

// EXAMPLE 4: Home Screen Integration
class HomeScreenWithHydration extends StatefulWidget {
  final String playerName;

  const HomeScreenWithHydration({
    super.key,
    required this.playerName,
  });

  @override
  State<HomeScreenWithHydration> createState() =>
      _HomeScreenWithHydrationState();
}

class _HomeScreenWithHydrationState extends State<HomeScreenWithHydration> {
  double totalConsumedMl = 1500;
  double dailyGoal = 3000;
  int streak = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        title: const Text('Home'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ... Existing home screen widgets ...

            // HYDRATION MINI WIDGET INTEGRATION
            HydrationMiniWidget(
              consumed: totalConsumedMl,
              goal: dailyGoal,
              streak: streak,
              onTap: () {
                HydrationNavigation.navigateToDashboard(
                  context,
                  widget.playerName,
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick action buttons row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Stats'),
                    onPressed: () {
                      HydrationNavigation.navigateToStats(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('Achievements'),
                    onPressed: () {
                      HydrationNavigation.navigateToAchievements(context);
                    },
                  ),
                ),
              ],
            ),

            // ... Rest of home screen ...
          ],
        ),
      ),
    );
  }
}

// EXAMPLE 5: Deep Link Handler
class DeepLinkHandler {
  static Route? generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

    // Handle hydration-related deep links
    if (uri.host == 'hydration') {
      switch (uri.path) {
        case '/dashboard':
          return MaterialPageRoute(
            builder: (context) => const HydrationDashboardScreen(
              playerName: 'Player',
            ),
          );
        case '/stats':
          return MaterialPageRoute(
            builder: (context) => const HydrationStatsScreen(),
          );
        case '/achievements':
          return MaterialPageRoute(
            builder: (context) => const HydrationAchievementsScreen(),
          );
        case '/setup':
          return MaterialPageRoute(
            builder: (context) => const HydrationGoalsSetupScreen(),
          );
      }
    }
    return null;
  }
}

// EXAMPLE 6: Settings Screen Integration
class SettingsScreenWithHydration extends StatelessWidget {
  const SettingsScreenWithHydration({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // ... Existing settings ...

        // Hydration Settings Section
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Hydration Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5F5F5),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.water_drop, color: Color(0xFF00D9FF)),
          title: const Text('Daily Hydration Goal'),
          subtitle: const Text('Configure your water intake target'),
          onTap: () {
            HydrationNavigation.navigateToDashboard(context, 'Player');
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications, color: Color(0xFF00D9FF)),
          title: const Text('Reminder Settings'),
          subtitle: const Text('Adjust reminder frequency and timing'),
          onTap: () {
            // Navigate to reminder settings (to be implemented)
          },
        ),
        ListTile(
          leading: const Icon(Icons.bar_chart, color: Color(0xFF00D9FF)),
          title: const Text('View Hydration Stats'),
          subtitle: const Text('See your water intake trends'),
          onTap: () {
            HydrationNavigation.navigateToStats(context);
          },
        ),

        // ... Rest of settings ...
      ],
    );
  }
}

// EXAMPLE 7: Profile Screen Integration
class ProfileScreenWithHydration extends StatelessWidget {
  const ProfileScreenWithHydration({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ... Existing profile info ...

          const SizedBox(height: 24),

          // Hydration Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF121B3A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00D9FF).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💧 Hydration Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF5F5F5),
                  ),
                ),
                const SizedBox(height: 16),
                HydrationProgressWidget(
                  consumed: 1500,
                  goal: 3000,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                    ),
                    onPressed: () {
                      HydrationNavigation.navigateToDashboard(
                        context,
                        'Player',
                      );
                    },
                    child: const Text(
                      'View Full Dashboard',
                      style: TextStyle(
                        color: Color(0xFF0A0E27),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ... Rest of profile ...
        ],
      ),
    );
  }
}

// EXAMPLE 8: Notifications with Deep Links
class NotificationWithHydrationDeepLink {
  static void handleHydrationReminderNotification(String? payload) {
    // Parse notification payload
    if (payload == null) return;

    final data = Uri.parse(payload);

    // Navigate to appropriate screen based on payload
    if (data.queryParameters['action'] == 'quick_log') {
      // Handle quick log from notification
    } else if (data.queryParameters['action'] == 'open_dashboard') {
      // Navigate to dashboard
    } else if (data.queryParameters['action'] == 'view_achievement') {
      // Navigate to achievement detail
    }
  }
}

// EXAMPLE 9: Tablet/Large Screen Layout
class HydrationDashboardLandscape extends StatelessWidget {
  const HydrationDashboardLandscape({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel - Progress and Quick Log
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF0A0E27),
            padding: const EdgeInsets.all(24),
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  // Dashboard content
                ],
              ),
            ),
          ),
        ),
        // Right panel - Stats
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF121B3A),
            padding: const EdgeInsets.all(24),
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  // Stats content
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// EXAMPLE 10: Integration with Provider for State Management
// (If using Provider package)

/*
class HydrationViewModel extends ChangeNotifier {
  double _consumedMl = 0;
  double _dailyGoal = 3000;
  int _streak = 0;

  double get consumedMl => _consumedMl;
  double get dailyGoal => _dailyGoal;
  int get streak => _streak;

  void logWater(double amount) {
    _consumedMl += amount;
    notifyListeners();
  }

  void resetDaily() {
    _consumedMl = 0;
    notifyListeners();
  }
}

// In your widget:
Consumer<HydrationViewModel>(
  builder: (context, viewModel, _) {
    return HydrationMiniWidget(
      consumed: viewModel.consumedMl,
      goal: viewModel.dailyGoal,
      streak: viewModel.streak,
      onTap: () { ... },
    );
  },
)
*/

// Import statements needed in your files:
/*
import 'package:solo_leveling/screens/hydration_dashboard_screen.dart';
import 'package:solo_leveling/screens/hydration_stats_screen.dart';
import 'package:solo_leveling/screens/hydration_achievements_screen.dart';
import 'package:solo_leveling/widgets/hydration_widgets.dart';
*/
