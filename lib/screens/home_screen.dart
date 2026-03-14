import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../models/achievement.dart';
import '../models/hydration_goal.dart';
import '../models/hydration_streak.dart';
import '../models/hydration_log.dart';
import '../services/storage_service.dart';
import '../widgets/hydration_widgets.dart';

class HomeScreen extends StatefulWidget {
  final String playerName;

  const HomeScreen({super.key, required this.playerName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  // Hydration Feature Data
  double totalConsumedMl = 0;
  double dailyGoalMl = 2000;
  int hydrationStreak = 0;

  // New features
  int dailyStreak = 0;
  int todayXp = 0;
  int weeklyXp = 0;
  List<Achievement> achievements = [];
  List<bool> weeklyCompletion = [
    true,
    true,
    false,
    true,
    true,
    false,
    true,
  ]; // Mon-Sun

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadDailyStreak();
    await _loadTodayXp();
    await _loadWeeklyStats();
    await _loadAchievements();
    await _loadHydrationData();
  }

  Future<void> _loadDailyStreak() async {
    final storage = StorageService();
    final lastLoginDateString = storage.getLastLoginDate();
    final savedStreakCount = storage.getDailyStreak();

    final today = DateTime.now();
    final todayDateString = '${today.year}-${today.month}-${today.day}';

    if (lastLoginDateString == null || lastLoginDateString != todayDateString) {
      // Check if yesterday was logged in to maintain streak
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayDateString =
          '${yesterday.year}-${yesterday.month}-${yesterday.day}';

      if (lastLoginDateString == yesterdayDateString) {
        dailyStreak = savedStreakCount + 1;
      } else {
        dailyStreak = lastLoginDateString == null ? 1 : 1; // Reset if gap
      }

      await storage.saveLastLoginDate(todayDateString);
      await storage.saveDailyStreak(dailyStreak);
    } else {
      dailyStreak = savedStreakCount;
    }

    setState(() {});
  }

  Future<void> _loadTodayXp() async {
    final storage = StorageService();
    final today = DateTime.now();

    final savedQuestsJsonData = storage.getQuestData(today);
    if (savedQuestsJsonData != null) {
      final decodedQuestList = jsonDecode(savedQuestsJsonData) as List;
      todayXp = 0;
      for (var quest in decodedQuestList) {
        if (quest['isCompleted'] ?? false) {
          final questXpReward = quest['xpReward'];
          if (questXpReward is int) {
            todayXp += questXpReward;
          } else if (questXpReward is num) {
            todayXp += questXpReward.toInt();
          }
        }
      }
    }

    // Add hydration XP to today's XP
    final hydrationXpToday = storage.getHydrationXpToday();
    todayXp += hydrationXpToday;

    // Load and apply total experience
    await _loadTotalExperience();

    setState(() {});
  }

  Future<void> _loadTotalExperience() async {
    final storage = StorageService();
    experience = storage.getTotalExperience();
    level = storage.getPlayerLevel();
    maxExperience = storage.getMaxExperience();
  }

  Future<void> _saveTotalExperience() async {
    final storage = StorageService();
    await storage.saveTotalExperience(experience);
    await storage.savePlayerLevel(level);
    await storage.saveMaxExperience(maxExperience);
  }

  Future<void> _addExperience(int xpToAdd) async {
    experience += xpToAdd;

    // Check for level up
    while (experience >= maxExperience) {
      experience -= maxExperience;
      level += 1;
      maxExperience = (maxExperience * 1.1)
          .toInt(); // Increase max XP by 10% per level
    }

    await _saveTotalExperience();
  }

  Future<void> _loadWeeklyStats() async {
    final storage = StorageService();
    weeklyXp = 0;

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final savedQuestsJsonData = storage.getQuestData(date);
      if (savedQuestsJsonData != null) {
        final decodedQuestList = jsonDecode(savedQuestsJsonData) as List;
        for (var quest in decodedQuestList) {
          if (quest['isCompleted'] ?? false) {
            final questXpReward = quest['xpReward'];
            if (questXpReward is int) {
              weeklyXp += questXpReward;
            } else if (questXpReward is num) {
              weeklyXp += questXpReward.toInt();
            }
            weeklyCompletion[6 - i] = true;
          }
        }
      }
    }

    setState(() {});
  }

  Future<void> _loadAchievements() async {
    // Initialize default achievements
    achievements = [
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Wake up on time for 3 days',
        icon: '🌅',
        category: 'Streak',
        progress: dailyStreak >= 3 ? 3 : dailyStreak,
        requirement: 3,
        isUnlocked: dailyStreak >= 3,
      ),
      Achievement(
        id: 'fitness_starter',
        title: 'Fitness Starter',
        description: 'Complete 5 workouts',
        icon: '💪',
        category: 'Fitness',
        progress: 3,
        requirement: 5,
      ),
      Achievement(
        id: 'bookworm',
        title: 'Bookworm',
        description: 'Read for 7 days',
        icon: '📖',
        category: 'Learning',
        progress: 4,
        requirement: 7,
      ),
      Achievement(
        id: 'perfect_day',
        title: 'Perfect Day',
        description: 'Complete all quests in one day',
        icon: '⭐',
        category: 'Quests',
        progress: 0,
        requirement: 1,
      ),
      Achievement(
        id: 'week_warrior',
        title: 'Week Warrior',
        description: 'Complete all quests for 7 days',
        icon: '🏆',
        category: 'Streak',
        progress: dailyStreak >= 7 ? 7 : dailyStreak,
        requirement: 7,
        isUnlocked: dailyStreak >= 7,
      ),
    ];

    setState(() {});
  }

  Future<void> _loadHydrationData() async {
    final storage = StorageService();

    // Load goal
    final goalJson = storage.getHydrationGoal();
    if (goalJson != null) {
      final goal = HydrationGoal.fromJson(jsonDecode(goalJson));
      dailyGoalMl = goal.dailyGoalMl;
    }

    // Load today's logs
    final logsJson = storage.getHydrationLogsToday();
    totalConsumedMl = 0;
    for (var logJson in logsJson) {
      final log = HydrationLog.fromJson(jsonDecode(logJson));
      totalConsumedMl += log.amountMl;
    }

    // Load streak
    final streakJson = storage.getHydrationStreak();
    if (streakJson != null) {
      final streak = HydrationStreak.fromJson(jsonDecode(streakJson));
      hydrationStreak = streak.currentStreak;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Column(
              children: [
                // Header with Player Name and Level
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.playerName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9F7AEA),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Awakened Hunter',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9F7AEA), Color(0xFF00D9FF)],
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
                ),
                const SizedBox(height: 20),

                // Daily Streak Counter
                _buildStreakCard(),
                const SizedBox(height: 20),

                // Today's XP Summary
                _buildTodayXpCard(),
                const SizedBox(height: 20),

                // Experience Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Experience',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '$experience / $maxExperience',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                      ],
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
                  ],
                ),
                const SizedBox(height: 24),

                // Hydration Mini Widget
                HydrationMiniWidget(
                  consumed: totalConsumedMl,
                  goal: dailyGoalMl,
                  streak: hydrationStreak,
                  onTap: () {
                    Navigator.of(context).pushNamed('/hydration/dashboard');
                  },
                ),
                const SizedBox(height: 24),

                // Weekly Stats
                _buildWeeklyStatsCard(),
                const SizedBox(height: 24),

                // Stats Grid
                Column(
                  children: [
                    _buildStatCard('HP', hp, maxHp, const Color(0xFFFF6B6B)),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      'Intelligence',
                      intelligence,
                      maxIntelligence,
                      const Color(0xFF4B7AFF),
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      'Strength',
                      strength,
                      100,
                      const Color(0xFF9F7AEA),
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      'Consistency',
                      consistency,
                      100,
                      const Color(0xFFFFB74D),
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      'Resilience',
                      resilience,
                      100,
                      const Color(0xFFFF8C42),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Recent Achievements
                _buildAchievementsSection(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B6B).withOpacity(0.2),
            const Color(0xFFFF8E71).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily Streak',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    '$dailyStreak',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'days',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Keep it up!',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayXpCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Progress",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$todayXp / 275 XP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D9FF),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D9FF), Color(0xFF9F7AEA)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('⭐', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsCard() {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Stats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9F7AEA),
                ),
              ),
              Text(
                '$weeklyXp XP',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D9FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              const dayAbbreviations = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final isDayCompleted = weeklyCompletion[index];
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDayCompleted
                          ? const Color(0xFF00D9FF).withOpacity(0.3)
                          : Colors.grey[900],
                      border: Border.all(
                        color: isDayCompleted
                            ? const Color(0xFF00D9FF)
                            : Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: isDayCompleted
                          ? const Icon(
                              Icons.check,
                              color: Color(0xFF00D9FF),
                              size: 16,
                            )
                          : Text(
                              dayAbbreviations[index],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayAbbreviations[index],
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final unlockedAchievementList = achievements
        .where((a) => a.isUnlocked)
        .toList();
    final recentUnlockedAchievements = unlockedAchievementList.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT ACHIEVEMENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (recentUnlockedAchievements.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                const Text(
                  'Keep completing quests to unlock achievements!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white54),
                ),
              ],
            ),
          )
        else
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: recentUnlockedAchievements.map((achievement) {
              return _buildAchievementCard(achievement);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFB74D).withOpacity(0.2),
            const Color(0xFFFF8A65).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB74D).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(achievement.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
              ),
            ],
          ),
          if (achievement.isUnlocked)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFB74D),
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String statLabel,
    int currentStatValue,
    int maximumStatValue,
    Color color,
  ) {
    double statFillPercentage = currentStatValue / maximumStatValue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            statLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$currentStatValue/$maximumStatValue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: statFillPercentage,
                  minHeight: 6,
                  backgroundColor: Colors.grey[900],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
