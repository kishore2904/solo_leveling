import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'screens/intro_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/name_input_screen.dart';
import 'screens/main_app.dart';
import 'screens/hydration_dashboard_screen.dart';
import 'screens/hydration_stats_screen.dart';
import 'screens/hydration_achievements_screen.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _playerName = '';
  bool _introComplete = false;
  bool _splashComplete = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    final savedPlayerName = StorageService().getPlayerName();

    setState(() {
      if (savedPlayerName != null && savedPlayerName.isNotEmpty) {
        _playerName = savedPlayerName;
        // Skip intro and splash if name is already saved
        _introComplete = true;
        _splashComplete = true;
      }
      _isLoading = false;
    });
  }

  void _onIntroComplete() {
    setState(() {
      _introComplete = true;
    });
  }

  void _onSplashComplete() {
    setState(() {
      _splashComplete = true;
    });
  }

  Future<void> _onNameSubmitted(String name) async {
    await StorageService().savePlayerName(name);

    setState(() {
      _playerName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solo Leveling',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.neonBlue),
      ),
      home: _isLoading ? const SizedBox() : _buildInitialScreen(),
      routes: {
        '/hydration/dashboard': (context) => HydrationDashboardScreen(
          playerName: _playerName,
        ),
        '/hydration/stats': (context) => const HydrationStatsScreen(),
        '/hydration/achievements': (context) =>
            const HydrationAchievementsScreen(),
      },
    );
  }

  Widget _buildInitialScreen() {
    // Show intro screen
    if (!_introComplete) {
      return IntroScreen(onGetStarted: _onIntroComplete);
    }

    // Show splash screen
    if (!_splashComplete) {
      return SplashScreen(onSplashComplete: _onSplashComplete);
    }

    // Show name input screen
    if (_playerName.isEmpty) {
      return NameInputScreen(onNameSubmitted: _onNameSubmitted);
    }

    // Show main app with navigation after name is entered
    return MainApp(playerName: _playerName);
  }
}
