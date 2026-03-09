import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../constants/colors.dart';

class NameInputScreen extends StatefulWidget {
  final Function(String) onNameSubmitted;

  const NameInputScreen({super.key, required this.onNameSubmitted});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _playerNameController = TextEditingController();
  bool _isPlayerNameEntered = false;

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  void _submitPlayerName() {
    if (_playerNameController.text.trim().isNotEmpty) {
      widget.onNameSubmitted(_playerNameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blurred background image
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Image.asset(
                'assets/images/name_entering.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark overlay for better text visibility
          Positioned.fill(
            child: Container(
              color: AppColors.darkBg.withOpacity(0.4),
            ),
          ),
          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome Hunter',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9F7AEA),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Enter Your Name',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _playerNameController,
                    onChanged: (value) {
                      setState(() {
                        _isPlayerNameEntered = value.trim().isNotEmpty;
                      });
                    },
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your hunter name',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF9F7AEA),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF9F7AEA),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF00D9FF),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: _isPlayerNameEntered
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF9F7AEA),
                                Color(0xFF00D9FF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey[700]!,
                                Colors.grey[800]!,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      onPressed: _isPlayerNameEntered ? _submitPlayerName : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Start Journey',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isPlayerNameEntered ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
