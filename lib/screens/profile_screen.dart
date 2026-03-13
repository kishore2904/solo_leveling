import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

class ProfileScreen extends StatefulWidget {
  final String playerName;

  const ProfileScreen({super.key, required this.playerName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int level = 1;
  int dailyStreak = 0;
  int totalQuestsCompleted = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevel = prefs.getInt('player_level') ?? 1;
    final savedStreak = prefs.getInt('daily_streak') ?? 0;
    final savedQuestsCompleted = prefs.getInt('total_quests_completed') ?? 0;

    setState(() {
      level = savedLevel;
      dailyStreak = savedStreak;
      totalQuestsCompleted = savedQuestsCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9F7AEA),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9F7AEA).withOpacity(0.3),
                      const Color(0xFF6B46C1).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF9F7AEA).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF9F7AEA),
                            Color(0xFF00D9FF),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '🔮',
                          style: TextStyle(fontSize: 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.playerName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9F7AEA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Awakened Hunter • Level $level',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Overview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D9FF).withOpacity(0.2),
                      const Color(0xFF9F7AEA).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00D9FF).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATS OVERVIEW',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Daily Streak', '🔥', '$dailyStreak days',
                        const Color(0xFFFF6B6B)),
                    const SizedBox(height: 12),
                    _buildStatRow('Quests Completed', '⚔️', '$totalQuestsCompleted',
                        const Color(0xFF00D9FF)),
                    const SizedBox(height: 12),
                    _buildStatRow('Current Level', '📊', 'Level $level',
                        const Color(0xFF9F7AEA)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9F7AEA).withOpacity(0.2),
                      const Color(0xFF6B46C1).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF9F7AEA).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ABOUT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Solo Leveling Quest Tracker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track your daily quests, earn XP, and level up as an Awakened Hunter. Complete your missions to gain strength and unlock achievements.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
      String label, String icon, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
