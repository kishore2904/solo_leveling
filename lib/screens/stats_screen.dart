import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int level = 1;
  int experience = 450;
  int maxExperience = 1000;
  int hp = 100;
  int maxHp = 100;
  int intelligence = 80;
  int maxIntelligence = 100;
  int strength = 75;
  int consistency = 65;
  int resilience = 70;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      level = prefs.getInt('player_level') ?? 1;
      experience = prefs.getInt('total_experience') ?? 450;
      maxExperience = prefs.getInt('max_experience') ?? 1000;
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
          'Stats',
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
              // Experience Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9F7AEA).withOpacity(0.3),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Level',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9F7AEA),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF9F7AEA),
                                Color(0xFF00D9FF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Lv. $level',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Experience',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: experience / maxExperience,
                        minHeight: 12,
                        backgroundColor: Colors.grey[900],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00D9FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$experience / $maxExperience XP',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00D9FF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Character Stats
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
                      'CHARACTER STATS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailedStatCard('HP', hp, maxHp, const Color(0xFFFF6B6B),
                        '❤️'),
                    const SizedBox(height: 12),
                    _buildDetailedStatCard('Intelligence', intelligence,
                        maxIntelligence, const Color(0xFF4B7AFF), '🧠'),
                    const SizedBox(height: 12),
                    _buildDetailedStatCard('Strength', strength, 100,
                        const Color(0xFF9F7AEA), '💪'),
                    const SizedBox(height: 12),
                    _buildDetailedStatCard('Consistency', consistency, 100,
                        const Color(0xFFFFB74D), '🎯'),
                    const SizedBox(height: 12),
                    _buildDetailedStatCard('Resilience', resilience, 100,
                        const Color(0xFFFF8C42), '🛡️'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6B46C1).withOpacity(0.2),
                      const Color(0xFF9F7AEA).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6B46C1).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STAT INFORMATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatInfo('HP', 'Health points - Reduce by taking damage'),
                    const SizedBox(height: 10),
                    _buildStatInfo('Intelligence',
                        'Mental power & strategy - Increases magical abilities'),
                    const SizedBox(height: 10),
                    _buildStatInfo('Strength',
                        'Physical power - Increases attack damage'),
                    const SizedBox(height: 10),
                    _buildStatInfo('Consistency',
                        'Daily dedication - Completed quests increase this'),
                    const SizedBox(height: 10),
                    _buildStatInfo('Resilience',
                        'Defense capability - Reduces damage taken'),
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

  Widget _buildDetailedStatCard(String label, int current, int max, Color color,
      String icon) {
    final percentage = (current / max * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '$current / $max',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: current / max,
              minHeight: 8,
              backgroundColor: Colors.grey[900],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatInfo(String stat, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00D9FF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
