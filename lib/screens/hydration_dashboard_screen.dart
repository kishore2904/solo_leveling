import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../models/hydration_goal.dart';
import '../models/hydration_log.dart';
import '../models/hydration_streak.dart';
import '../models/hydration_score.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/hydration_calculation_service.dart';
import '../services/hydration_xp_service.dart';
import '../services/adaptive_reminder_service.dart';
import '../services/achievement_unlock_service.dart';
import '../services/daily_reset_service.dart';

class HydrationDashboardScreen extends StatefulWidget {
  final String playerName;

  const HydrationDashboardScreen({super.key, required this.playerName});

  @override
  State<HydrationDashboardScreen> createState() =>
      _HydrationDashboardScreenState();
}

class _HydrationDashboardScreenState extends State<HydrationDashboardScreen> {
  final storage = StorageService();
  HydrationGoal? goal;
  List<HydrationLog> todayLogs = [];
  HydrationStreak? streak;
  HydrationScore? dailyScore;

  double totalConsumedMl = 0;
  int progressPercentage = 0;
  int hydrationXpToday = 0;

  // Service instances
  final NotificationService _notificationService = NotificationService();
  final HydrationCalculationService _calculationService =
      HydrationCalculationService();
  final HydrationXpService _xpService = HydrationXpService();
  final AdaptiveReminderService _reminderService = AdaptiveReminderService();
  final AchievementUnlockService _achievementService =
      AchievementUnlockService();
  final DailyResetService _resetService = DailyResetService();

  final List<Map<String, dynamic>> quickLogButtons = [
    {'amount': 200, 'label': AppStrings.quickLog200ml, 'icon': '🥤'},
    {'amount': 250, 'label': AppStrings.quickLogGlass, 'icon': '🥛'},
    {'amount': 500, 'label': AppStrings.quickLogBottle, 'icon': '💧'},
    {'amount': 750, 'label': AppStrings.quickLog3xGlass, 'icon': '💦'},
    {'amount': 1000, 'label': AppStrings.quickLog1L, 'icon': '🌊'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Initialize all services with error handling
      try {
        await _notificationService.initialize();
      } catch (e) {
        print('Error initializing NotificationService: $e');
      }

      try {
        await _resetService.initialize();
      } catch (e) {
        print('Error initializing DailyResetService: $e');
      }

      try {
        await _resetService.recordAppStartDate();
      } catch (e) {
        print('Error recording app start date: $e');
      }

      try {
        await _achievementService.initializeAchievements();
      } catch (e) {
        print('Error initializing AchievementUnlockService: $e');
      }

      try {
        await _reminderService.initializeReminders();
      } catch (e) {
        print('Error initializing AdaptiveReminderService: $e');
      }
      
      await _loadHydrationData();
    } catch (e) {
      print('Error in _initializeData: $e');
    }
  }

  @override
  void dispose() {
    _reminderService.dispose();
    _resetService.dispose();
    super.dispose();
  }

  Future<void> _loadHydrationData() async {
    final goalJson = storage.getHydrationGoal();
    final logsJson = storage.getHydrationLogsToday();
    final streakJson = storage.getHydrationStreak();
    final scoreJson = storage.getHydrationScoreToday();
    final xpToday = storage.getHydrationXpToday();

    setState(() {
      if (goalJson != null) {
        goal = HydrationGoal.fromJson(jsonDecode(goalJson));
      }

      todayLogs = logsJson
          .map((log) => HydrationLog.fromJson(jsonDecode(log)))
          .toList();
      totalConsumedMl = todayLogs.fold(0, (sum, log) => sum + log.amountMl);

      if (goal != null) {
        progressPercentage = ((totalConsumedMl / goal!.dailyGoalMl) * 100)
            .toInt()
            .clamp(0, 100);
      }

      if (streakJson != null) {
        streak = HydrationStreak.fromJson(jsonDecode(streakJson));
      }

      if (scoreJson != null) {
        dailyScore = HydrationScore.fromJson(jsonDecode(scoreJson));
      }

      hydrationXpToday = xpToday;
    });
  }

  Future<void> _logWater(double amountMl, String source) async {
    try {
      final log = HydrationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amountMl: amountMl,
        timestamp: DateTime.now(),
        source: source,
        dateLogged: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ),
      );

      todayLogs.add(log);
      final logsJson =
          todayLogs.map((l) => jsonEncode(l.toJson())).toList();
      await storage.saveHydrationLogsToday(logsJson);

      // Calculate new hydration score
      await _updateHydrationScore();

      // Check for goal reached
      if (goal != null && totalConsumedMl >= goal!.dailyGoalMl && 
          (totalConsumedMl - amountMl) < goal!.dailyGoalMl) {
        // Just reached goal - award XP
        try {
          final xpReward = await _xpService.awardDailyGoalXp(
            consumedMl: totalConsumedMl.toInt(),
            dailyGoalMl: goal!.dailyGoalMl.toInt(),
          );
          
          await _notificationService.sendGoalReachedNotification(
            consumedMl: totalConsumedMl.toInt(),
            goalMl: goal!.dailyGoalMl.toInt(),
            notificationId: _generateNotificationId(),
          );
          
          // Show XP reward
          _showXpRewardNotification(xpReward);
        } catch (e) {
          print('Error awarding goal XP: $e');
        }
      }

      // Check for achievements
      try {
        await _checkAndUnlockAchievements();
      } catch (e) {
        print('Error checking achievements: $e');
      }

      // Check for streak milestones
      if (goal != null && totalConsumedMl >= goal!.dailyGoalMl) {
        try {
          await _checkStreakMilestone();
        } catch (e) {
          print('Error checking streak: $e');
        }
      }

      await _loadHydrationData();
      _showLogConfirmation(amountMl);
    } catch (e) {
      print('Error in _logWater: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.errorLoggingWater}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateHydrationScore() async {
    if (goal == null) return;

    final intakePercentage = (totalConsumedMl / goal!.dailyGoalMl) * 100;
    int score = intakePercentage.clamp(0, 100).toInt();

    // Bonus points
    if (todayLogs.length >= 5) {
      score = (score * 1.1).toInt().clamp(0, 100);
    }

    final dailyScore = HydrationScore(
      id: 'score_${DateTime.now().toIso8601String()}',
      score: score,
      intakePercentage: intakePercentage,
      timelinessBonus: todayLogs.length >= 3 ? 10 : 0,
      responseBonus: 5,
      ignoreDeduction: 0,
      dateRecorded: DateTime.now(),
    );

    await storage.saveHydrationScoreToday(jsonEncode(dailyScore.toJson()));
  }

  Future<void> _checkAndUnlockAchievements() async {
    if (goal == null || streak == null) return;

    // Get all logs to calculate total water intake
    final allLogsJson = storage.getHydrationLogsToday();
    int totalConsumption = 0;
    for (var logJson in allLogsJson) {
      final log = HydrationLog.fromJson(jsonDecode(logJson));
      totalConsumption += log.amountMl.toInt();
    }

    // Calculate total water intake since app start
    final history = await _resetService.getHistoryLastNDays(365);
    int totalWaterIntakeMl = history.values.fold(0, (sum, val) => sum + val);

    final unlockedAchievements = await _achievementService.checkAndUnlockAchievements(
      totalConsumedMl: totalConsumption,
      dailyGoalMl: goal!.dailyGoalMl.toInt(),
      currentStreak: streak!.currentStreak,
      totalDaysTracked: await _resetService.getDaysSinceStart(),
      totalWaterIntakeMl: totalWaterIntakeMl,
      loggingDates: allLogsJson
          .map((logJson) {
            try {
              final log = HydrationLog.fromJson(jsonDecode(logJson));
              return log.timestamp;
            } catch (e) {
              return DateTime.now();
            }
          })
          .toList(),
    );

    if (unlockedAchievements.isNotEmpty) {
      _showAchievementNotification(unlockedAchievements.first);
    }
  }

  Future<void> _checkStreakMilestone() async {
    if (streak == null) return;

    final milestones = [7, 14, 30, 100, 365];
    if (milestones.contains(streak!.currentStreak)) {
      await _notificationService.sendStreakMilestoneNotification(
        streakDays: streak!.currentStreak,
        notificationId: _generateNotificationId(),
      );
    }
  }

  void _showAchievementNotification(String achievementId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppStrings.achievementUnlockedMsg}: $achievementId'),
        backgroundColor: const Color(0xFFFFD700),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLogConfirmation(double amount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppStrings.checkMark} $amount ${AppStrings.waterLoggedMsg}'),
        backgroundColor: const Color(0xFF00D9FF),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showXpRewardNotification(int xp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+$xp XP 🎉'),
        backgroundColor: const Color(0xFF00D9FF),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCustomLogDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121B3A),
        title: const Text(
          AppStrings.customAmount,
          style: TextStyle(color: Color(0xFFF5F5F5)),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter amount in ml',
            hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF00D9FF)),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          style: const TextStyle(color: Color(0xFFF5F5F5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                _logWater(amount, 'manual');
                Navigator.pop(context);
              }
            },
            child: const Text(AppStrings.log),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        title: const Text(
          '💧 ${AppStrings.hydrationDashboard}',
          style: TextStyle(
            color: Color(0xFF00D9FF),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: goal == null
          ? _buildSetupPrompt()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Daily Goal Progress Card
                  _buildProgressCard(),
                  const SizedBox(height: 24),

                  // Quick Log Buttons
                  _buildQuickLogSection(),
                  const SizedBox(height: 24),

                  // Today's Stats
                  _buildTodayStats(),
                  const SizedBox(height: 24),

                  // Streak Card
                  if (streak != null) _buildStreakCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSetupPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D9FF), Color(0xFF00F0FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.water_drop,
              size: 60,
              color: Color(0xFF0A0E27),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            AppStrings.welcomeHydration,
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Set up your daily hydration goal to get started with smart water reminders.',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HydrationGoalsSetupScreen(),
                ),
              ).then((_) => _initializeData());
            },
            child: const Text(
              AppStrings.setupGoal,
              style: TextStyle(
                color: Color(0xFF0A0E27),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121B3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.todayProgress,
                    style: TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${totalConsumedMl.toStringAsFixed(0)} / ${goal?.dailyGoalMl.toStringAsFixed(0)} ml',
                    style: const TextStyle(
                      color: Color(0xFFF5F5F5),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$progressPercentage%',
                  style: const TextStyle(
                    color: Color(0xFF00D9FF),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: (progressPercentage / 100).clamp(0, 1),
              backgroundColor: const Color(0xFF00D9FF).withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progressPercentage),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Progress Message
          Text(
            _getProgressMessage(progressPercentage),
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.quickLog,
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...quickLogButtons.map((btn) {
              return _buildQuickLogButton(
                icon: btn['icon'],
                label: btn['label'],
                amount: btn['amount'],
              );
            }),
            _buildCustomLogButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickLogButton({
    required String icon,
    required String label,
    required int amount,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _logWater(amount.toDouble(), 'quick_button'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00D9FF).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomLogButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showCustomLogDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF00F0FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00F0FF),
              width: 1,
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✏️', style: TextStyle(fontSize: 24)),
              SizedBox(height: 4),
              Text(
                'Custom',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121B3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Summary',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Total Logs', todayLogs.length.toString()),
              _buildStatItem(
                'Hydration XP',
                '+$hydrationXpToday',
              ),
              _buildStatItem(
                'Score',
                dailyScore?.score.toString() ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB0B0B0),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00D9FF),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00D9FF),
            Color(0xFF00F0FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔥 Hydration Streak',
                style: TextStyle(
                  color: Color(0xFF0A0E27),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${streak?.currentStreak} Days',
                style: const TextStyle(
                  color: Color(0xFF0A0E27),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Best Streak',
                style: TextStyle(
                  color: Color(0xFF0A0E27),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${streak?.longestStreak} Days',
                style: const TextStyle(
                  color: Color(0xFF0A0E27),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(int percentage) {
    if (percentage < 25) return const Color(0xFFFF6B6B);
    if (percentage < 50) return const Color(0xFFFFA500);
    if (percentage < 75) return const Color(0xFF64E7FF);
    return const Color(0xFF00D9FF);
  }

  String _getProgressMessage(int percentage) {
    if (percentage == 0) return 'Start your day with a glass of water! 💧';
    if (percentage < 25) return 'Great start! Keep going!';
    if (percentage < 50) return 'You\'re halfway there! 🎯';
    if (percentage < 75) return 'Almost done! Keep it up! 💪';
    if (percentage < 100) return 'Just a bit more to reach your goal!';
    if (percentage == 100) return 'Goal achieved! 🎉';
    return 'Exceeded your goal! Extra hydration! 🏆';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.toInt() % 100000;
  }
}

// Goal Setup Screen
class HydrationGoalsSetupScreen extends StatefulWidget {
  const HydrationGoalsSetupScreen({super.key});

  @override
  State<HydrationGoalsSetupScreen> createState() =>
      _HydrationGoalsSetupScreenState();
}

class _HydrationGoalsSetupScreenState extends State<HydrationGoalsSetupScreen> {
  final storage = StorageService();

  // Form fields
  double weight = 70;
  String activityLevel = 'Moderate';
  double dailyGoal = 2000;
  TimeOfDay wakeUpTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay sleepTime = const TimeOfDay(hour: 23, minute: 0);
  int reminderInterval = 120;
  bool autoCalculate = true;

  final List<String> activityLevels = [
    'Sedentary',
    'Light',
    'Moderate',
    'High',
    'VeryHigh'
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveGoal() async {
    final goal = HydrationGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dailyGoalMl: dailyGoal,
      userWeight: weight,
      activityLevel: activityLevel,
      wakeUpTime: wakeUpTime,
      sleepTime: sleepTime,
      reminderIntervalMinutes: reminderInterval,
      autoCalculateGoal: autoCalculate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await storage.saveHydrationGoal(jsonEncode(goal.toJson()));

    // Create initial streak
    final streak = HydrationStreak(
      id: 'streak_1',
      currentStreak: 0,
      longestStreak: 0,
      lastCompletionDate: DateTime.now(),
      streakDates: [],
    );
    await storage.saveHydrationStreak(jsonEncode(streak.toJson()));

    // Initialize reminder service
    final reminderService = AdaptiveReminderService();
    await reminderService.startSmartReminders();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        title: const Text(
          'Set Up Hydration Goal',
          style: TextStyle(
            color: Color(0xFF00D9FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00D9FF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSliderSection(
              'Weight (kg)',
              weight,
              40,
              150,
              (value) => setState(() => weight = value),
            ),
            const SizedBox(height: 24),
            _buildDropdownSection(
              'Activity Level',
              activityLevel,
              (value) => setState(() => activityLevel = value ?? 'Moderate'),
            ),
            const SizedBox(height: 24),
            _buildSliderSection(
              'Daily Goal (ml)',
              dailyGoal,
              1000,
              4000,
              (value) => setState(() => dailyGoal = value),
            ),
            const SizedBox(height: 24),
            _buildTimeSection(
              'Wake Up Time',
              wakeUpTime,
              () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: wakeUpTime,
                );
                if (time != null) {
                  setState(() => wakeUpTime = time);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildTimeSection(
              'Sleep Time',
              sleepTime,
              () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: sleepTime,
                );
                if (time != null) {
                  setState(() => sleepTime = time);
                }
              },
            ),
            const SizedBox(height: 24),
            _buildSliderSection(
              'Reminder Interval (minutes)',
              reminderInterval.toDouble(),
              60,
              360,
              (value) => setState(() => reminderInterval = value.toInt()),
            ),
            const SizedBox(height: 24),
            _buildAutoCalculateToggle(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _saveGoal,
                child: const Text(
                  'Save & Continue',
                  style: TextStyle(
                    color: Color(0xFF0A0E27),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF5F5F5),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF00D9FF),
            inactiveTrackColor: const Color(0xFF00D9FF).withOpacity(0.2),
            thumbColor: const Color(0xFF00D9FF),
            overlayColor: const Color(0xFF00D9FF).withOpacity(0.3),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSection(
    String label,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00D9FF), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF121B3A),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00D9FF)),
            onChanged: onChanged,
            items: activityLevels.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    level,
                    style: const TextStyle(color: Color(0xFFF5F5F5)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection(
    String label,
    TimeOfDay time,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00D9FF), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFFF5F5F5),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.access_time, color: Color(0xFF00D9FF)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoCalculateToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121B3A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Goal Calculation',
                  style: TextStyle(
                    color: Color(0xFFF5F5F5),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Auto-calculate based on weight & activity',
                  style: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: autoCalculate,
            onChanged: (value) => setState(() => autoCalculate = value),
            activeThumbColor: const Color(0xFF00D9FF),
            activeTrackColor: const Color(0xFF00D9FF).withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
