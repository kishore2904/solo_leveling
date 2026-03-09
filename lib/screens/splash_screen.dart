import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../constants/colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onSplashComplete;

  const SplashScreen({super.key, required this.onSplashComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  String _statusText = 'Awakening Hunter...';

  final List<String> _statusMessages = [
    'Awakening Hunter...',
    'Loading System...',
    'Analyzing Abilities...',
    'Preparing Dungeons...',
  ];

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() async {
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() {
        _progress = i / 100;
        // Update status text based on progress
        int messageIndex = (i ~/ 25).clamp(0, _statusMessages.length - 1);
        _statusText = _statusMessages[messageIndex];
      });
    }
    // Call the callback after loading is complete
    widget.onSplashComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blurred background image
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Image.asset(
                'assets/images/loading_screen.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark overlay
          Positioned.fill(
            child: Container(
              color: AppColors.darkBg.withOpacity(0.5),
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with glow effect
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      const Color(0xFF9F7AEA),
                      const Color(0xFF00D9FF),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'ARISE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 80),
                // Progress bar container
                SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 12,
                          backgroundColor: const Color(0xFF2D1B4E).withOpacity(0.5),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _statusText,
                          key: ValueKey<String>(_statusText),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9F7AEA),
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
