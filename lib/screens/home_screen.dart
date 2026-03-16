import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../models/achievement.dart';
import '../models/hydration_goal.dart';
import '../models/hydration_streak.dart';
import '../models/hydration_log.dart';
import '../models/reminder_task.dart';
import '../services/storage_service.dart';
import '../services/level_progression_service.dart';
import '../widgets/index.dart';
import 'add_task_screen.dart';
import 'reminders_screen.dart';

class HomeScreen extends StatefulWidget {
  final String playerName;

  const HomeScreen({super.key, required this.playerName});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final levelService = LevelProgressionService();

  int level = 1;
  int currentXp = 0;
  int requiredXpForNextLevel = 250;
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
  
  // Upcoming Reminders
  List<ReminderTask> upcomingReminders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAllData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh upcoming reminders when app returns to foreground
      _loadUpcomingReminders();
    }
  }

  Future<void> _loadAllData() async {
    await _loadDailyStreak();
    await _loadTodayXp();
    await _loadWeeklyStats();
    await _loadAchievements();
    await _loadHydrationData();
    await _loadUpcomingReminders();
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

    // Load and apply total experience using new level progression system
    await _loadPlayerLevel();

    setState(() {});
  }

  Future<void> _loadPlayerLevel() async {
    final storage = StorageService();
    final totalXpEarned = storage.getTotalXpEarned();
    final levelInfo = levelService.calculateLevelFromTotalXp(totalXpEarned);

    level = levelInfo['level']!;
    currentXp = levelInfo['currentXp']!;
    requiredXpForNextLevel = levelInfo['requiredXp']!;
  }

  // Public method to refresh player level data (called when returning from other screens)
  Future<void> refreshPlayerLevel() async {
    await _loadPlayerLevel();
    setState(() {});
  }

  Future<void> _addQuestXp(int xpToAdd) async {
    final storage = StorageService();
    final previousTotalXp = storage.getTotalXpEarned();
    final newTotalXp = previousTotalXp + xpToAdd;

    // Save new total XP
    await storage.addTotalXpEarned(xpToAdd);

    // Check if user leveled up
    final levelUpInfo = levelService.checkLevelUp(
      previousTotalXp: previousTotalXp,
      newTotalXp: newTotalXp,
    );

    if (levelUpInfo['leveledUp'] as bool) {
      _showLevelUpNotification(levelUpInfo['newLevel'] as int);
    }

    // Reload player level
    await _loadPlayerLevel();
    setState(() {});
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

  void _showLevelUpNotification(int newLevel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('⭐ ', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Level Up!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'You reached Level $newLevel',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF9F7AEA),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _loadUpcomingReminders() async {
    try {
      final storage = StorageService();
      final savedRemindersJson = storage.getReminderData();
      List<ReminderTask> reminders = [];

      if (savedRemindersJson != null) {
        final remindersList = jsonDecode(savedRemindersJson) as List;
        for (var reminderJson in remindersList) {
          final reminder = ReminderTask.fromJson(reminderJson);
          // Only show uncompleted reminders
          if (!reminder.isCompleted) {
            reminders.add(reminder);
          }
        }
      }

      // Filter reminders for today and next 7 days
      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));
      
      upcomingReminders = reminders.where((reminder) {
        return reminder.scheduledTime.isAfter(
          DateTime(now.year, now.month, now.day),
        ) && reminder.scheduledTime.isBefore(
          DateTime(sevenDaysLater.year, sevenDaysLater.month, sevenDaysLater.day + 1),
        );
      }).toList();

      // Sort by scheduled time
      upcomingReminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      
      // Keep only the first 5 upcoming reminders
      if (upcomingReminders.length > 5) {
        upcomingReminders = upcomingReminders.sublist(0, 5);
      }

      setState(() {});
    } catch (e) {
      print('Error loading upcoming reminders: $e');
    }
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
                StreakCard(streakCount: dailyStreak),
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
                          '$currentXp / $requiredXpForNextLevel',
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
                        value: currentXp / requiredXpForNextLevel,
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

                // Upcoming Reminders Dashboard
                _buildUpcomingRemindersCard(),
                const SizedBox(height: 24),

                // Weekly Stats
                _buildWeeklyStatsCard(),
                const SizedBox(height: 24),

                // Stats Grid
                Column(
                  children: [
                    StatCard(label: 'HP', currentValue: hp, maxValue: maxHp, color: const Color(0xFFFF6B6B)),
                    const SizedBox(height: 12),
                    StatCard(
                      label: 'Intelligence',
                      currentValue: intelligence,
                      maxValue: maxIntelligence,
                      color: const Color(0xFF4B7AFF),
                    ),
                    const SizedBox(height: 12),
                    StatCard(
                      label: 'Strength',
                      currentValue: strength,
                      maxValue: 100,
                      color: const Color(0xFF9F7AEA),
                    ),
                    const SizedBox(height: 12),
                    StatCard(
                      label: 'Consistency',
                      currentValue: consistency,
                      maxValue: 100,
                      color: const Color(0xFFFFB74D),
                    ),
                    const SizedBox(height: 12),
                    StatCard(
                      label: 'Resilience',
                      currentValue: resilience,
                      maxValue: 100,
                      color: const Color(0xFFFF8C42),
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

  Widget _buildUpcomingRemindersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.neonBlue.withOpacity(0.15),
            AppColors.neonCyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.neonBlue.withOpacity(0.5),
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
                '📋 Upcoming Tasks',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonBlue,
                ),
              ),
              Text(
                '${upcomingReminders.length} tasks',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcomingReminders.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                '✨ No upcoming tasks! You\'re all set.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: List.generate(upcomingReminders.length, (index) {
                final reminder = upcomingReminders[index];
                final isToday = reminder.scheduledTime.year == DateTime.now().year &&
                    reminder.scheduledTime.month == DateTime.now().month &&
                    reminder.scheduledTime.day == DateTime.now().day;
                final isTomorrow = reminder.scheduledTime.year == DateTime.now().add(const Duration(days: 1)).year &&
                    reminder.scheduledTime.month == DateTime.now().add(const Duration(days: 1)).month &&
                    reminder.scheduledTime.day == DateTime.now().add(const Duration(days: 1)).day;
                
                final dateLabel = isToday
                    ? 'Today'
                    : isTomorrow
                        ? 'Tomorrow'
                        : '${reminder.scheduledTime.day}/${reminder.scheduledTime.month}';
                
                return Column(
                  children: [
                    if (index > 0) const Divider(color: Colors.white12, height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // Task Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.neonBlue.withOpacity(0.2),
                            ),
                            child: Text(reminder.icon, style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          // Task Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reminder.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$dateLabel · ${reminder.scheduledTime.hour.toString().padLeft(2, '0')}:${reminder.scheduledTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Priority Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: reminder.priority == 'High'
                                  ? const Color(0xFFFF6B6B).withOpacity(0.2)
                                  : reminder.priority == 'Medium'
                                      ? AppColors.neonBlue.withOpacity(0.2)
                                      : Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              reminder.priority == 'High'
                                  ? '🔴'
                                  : reminder.priority == 'Medium'
                                      ? '🟡'
                                      : '🟢',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          if (upcomingReminders.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/reminders');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonBlue.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'View All Tasks',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neonBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
              return AchievementCard(achievement: achievement);
            }).toList(),
          ),
      ],
    );
  }

}
