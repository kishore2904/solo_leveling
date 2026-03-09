import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/colors.dart';
import 'screens/intro_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/name_input_screen.dart';
import 'screens/home_screen.dart';

void main() {
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
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('player_name');
    
    setState(() {
      if (savedName != null && savedName.isNotEmpty) {
        _playerName = savedName;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_name', name);
    
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
      home: _isLoading ? const SizedBox() : _buildHome(),
    );
  }

  Widget _buildHome() {
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

    // Show main home screen after name is entered
    return HomeScreen(playerName: _playerName);
  }
}
