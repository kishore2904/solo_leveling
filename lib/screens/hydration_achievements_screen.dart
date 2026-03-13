import 'package:flutter/material.dart';

class HydrationAchievementsScreen extends StatefulWidget {
  const HydrationAchievementsScreen({super.key});

  @override
  State<HydrationAchievementsScreen> createState() =>
      _HydrationAchievementsScreenState();
}

class _HydrationAchievementsScreenState
    extends State<HydrationAchievementsScreen> {
  // Hard-coded achievements for demo
  final List<Map<String, dynamic>> achievements = [
    {
      'title': 'First Drop',
      'icon': '💧',
      'description': 'Log your first glass of water',
      'xpReward': 10,
      'unlocked': true,
      'category': 'Beginner',
      'progress': 100,
    },
    {
      'title': 'Morning Hydrator',
      'icon': '🌅',
      'description': 'Log water before 9:00 AM for 3 consecutive days',
      'xpReward': 25,
      'unlocked': true,
      'category': 'Habit',
      'progress': 100,
    },
    {
      'title': 'Hydration Starter',
      'icon': '✨',
      'description': 'Complete your daily goal for the first time',
      'xpReward': 50,
      'unlocked': true,
      'category': 'Milestone',
      'progress': 100,
    },
    {
      'title': 'Weekly Water Warrior',
      'icon': '⚔️',
      'description': 'Meet daily goal for 7 consecutive days',
      'xpReward': 100,
      'unlocked': true,
      'category': 'Challenge',
      'progress': 100,
    },
    {
      'title': 'Hydration Hero',
      'icon': '🦸',
      'description': 'Maintain a 30-day hydration streak',
      'xpReward': 250,
      'unlocked': false,
      'category': 'Challenge',
      'progress': 20,
    },
    {
      'title': 'Water Master',
      'icon': '👑',
      'description': 'Complete 100 days of hydration goals',
      'xpReward': 500,
      'unlocked': false,
      'category': 'Legendary',
      'progress': 15,
    },
    {
      'title': 'Consistency King',
      'icon': '👑',
      'description': 'Never miss a day for 2 months',
      'xpReward': 300,
      'unlocked': false,
      'category': 'Legendary',
      'progress': 40,
    },
    {
      'title': 'Night Owl Hydrator',
      'icon': '🌙',
      'description': 'Log water after 8:00 PM for 10 days',
      'xpReward': 50,
      'unlocked': false,
      'category': 'Habit',
      'progress': 60,
    },
    {
      'title': 'Never Ignore',
      'icon': '📲',
      'description': 'Respond to 95%+ of notifications in a week',
      'xpReward': 75,
      'unlocked': false,
      'category': 'Engagement',
      'progress': 50,
    },
    {
      'title': 'Smart Pacer',
      'icon': '⏱️',
      'description': 'Maintain perfect reminder response for 7 days',
      'xpReward': 100,
      'unlocked': false,
      'category': 'Engagement',
      'progress': 35,
    },
  ];

  late List<Map<String, dynamic>> unlockedAchievements;
  late List<Map<String, dynamic>> lockedAchievements;

  @override
  void initState() {
    super.initState();
    _categorizeAchievements();
  }

  void _categorizeAchievements() {
    unlockedAchievements =
        achievements.where((a) => a['unlocked'] as bool).toList();
    lockedAchievements =
        achievements.where((a) => !(a['unlocked'] as bool)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        title: const Text(
          '🏆 Achievements',
          style: TextStyle(
            color: Color(0xFF00D9FF),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Bar
            _buildStatsBar(),
            const SizedBox(height: 24),

            // Unlocked Section
            if (unlockedAchievements.isNotEmpty) ...[
              _buildSectionTitle('Unlocked (${unlockedAchievements.length})'),
              const SizedBox(height: 12),
              _buildAchievementsGrid(unlockedAchievements, isUnlocked: true),
              const SizedBox(height: 32),
            ],

            // Locked Section
            if (lockedAchievements.isNotEmpty) ...[
              _buildSectionTitle('In Progress (${lockedAchievements.length})'),
              const SizedBox(height: 12),
              _buildAchievementsGrid(lockedAchievements, isUnlocked: false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9FF), Color(0xFF00F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Total XP', '${unlockedAchievements.length * 75}'),
          _buildStatColumn(
              'Unlocked', '${unlockedAchievements.length}/${achievements.length}'),
          _buildStatColumn('Progress', '${((unlockedAchievements.length / achievements.length) * 100).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0A0E27),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0A0E27),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFF5F5F5),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAchievementsGrid(
    List<Map<String, dynamic>> achievementsList, {
    required bool isUnlocked,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: achievementsList.length,
      itemBuilder: (context, index) {
        final achievement = achievementsList[index];
        return _buildAchievementCard(achievement, isUnlocked);
      },
    );
  }

  Widget _buildAchievementCard(
    Map<String, dynamic> achievement,
    bool isUnlocked,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAchievementDetail(achievement),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121B3A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked
                  ? const Color(0xFF00D9FF)
                  : const Color(0xFF00D9FF).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? Colors.transparent
                        : const Color(0xFF00D9FF).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon and Lock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          achievement['icon'],
                          style: const TextStyle(fontSize: 32),
                        ),
                        if (!isUnlocked)
                          const Icon(
                            Icons.lock,
                            color: Color(0xFFB0B0B0),
                            size: 20,
                          ),
                      ],
                    ),
                    // Content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUnlocked)
                          _buildProgressBar(achievement['progress']),
                        const SizedBox(height: 8),
                        Text(
                          achievement['title'],
                          style: const TextStyle(
                            color: Color(0xFFF5F5F5),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${achievement['xpReward']} XP',
                          style: TextStyle(
                            color: isUnlocked
                                ? const Color(0xFF00D9FF)
                                : const Color(0xFFB0B0B0),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Unlock Badge
              if (isUnlocked)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '✓',
                      style: TextStyle(
                        color: Color(0xFF0A0E27),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: progress / 100,
            backgroundColor: const Color(0xFF00D9FF).withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFF00D9FF),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$progress%',
          style: const TextStyle(
            color: Color(0xFFB0B0B0),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _showAchievementDetail(Map<String, dynamic> achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF121B3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFF00D9FF),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                achievement['icon'],
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                achievement['title'],
                style: const TextStyle(
                  color: Color(0xFFF5F5F5),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  achievement['category'],
                  style: const TextStyle(
                    color: Color(0xFF00D9FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                achievement['description'],
                style: const TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (!achievement['unlocked'])
                Column(
                  children: [
                    _buildProgressBar(achievement['progress']),
                    const SizedBox(height: 16),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${achievement['xpReward']} XP',
                      style: const TextStyle(
                        color: Color(0xFF00D9FF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (achievement['unlocked'] as bool)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Unlocked',
                        style: TextStyle(
                          color: Color(0xFF0A0E27),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
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
      ),
    );
  }
}
