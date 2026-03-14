import 'dart:async';
import 'dart:convert';
import 'package:solo_leveling/models/hydration_streak.dart';
import 'package:solo_leveling/models/hydration_score.dart';
import 'storage_service.dart';
import 'achievement_unlock_service.dart';
import 'hydration_calculation_service.dart';

class DailyResetService {
  static final DailyResetService _instance = DailyResetService._internal();
  final storage = StorageService();

  factory DailyResetService() {
    return _instance;
  }

  DailyResetService._internal();

  Timer? _resetTimer;
  final AchievementUnlockService _achievementService = AchievementUnlockService();
  final HydrationCalculationService _calculationService =
      HydrationCalculationService();

  /// Initialize daily reset check
  Future<void> initialize() async {
    await checkAndReset();
    _scheduleNextReset();
  }

  /// Check if it's a new day and reset if needed
  Future<bool> checkAndReset() async {
    final lastResetDateStr = storage.getLastResetDate();
    final today = _getDateString(DateTime.now());

    if (lastResetDateStr != today) {
      // It's a new day
      await _performDailyReset();
      return true;
    }

    return false;
  }

  /// Perform the daily reset
  Future<void> _performDailyReset() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = _getDateString(yesterday);

    // Save yesterday's logs to history
    final logsJson = storage.getHydrationLogsToday();
    if (logsJson.isNotEmpty) {
      final historyKey = 'hydration_logs_$yesterdayStr';
      await storage.saveHydrationLogsForDate(yesterday, logsJson);
    }

    // Update streak
    await _updateStreakForNewDay();

    // Archive yesterday's score
    final yesterdayScore = storage.getHydrationScoreToday();
    if (yesterdayScore != null) {
      await storage.saveLastHydrationScore(yesterdayScore);
    }

    // Reset daily data
    await storage.clearHydrationLogsToday();
    await storage.clearHydrationScoreToday();
    await storage.resetHydrationXpToday();

    // Update last reset date
    await storage.saveLastResetDate(_getDateString(DateTime.now()));
  }

  /// Update streak for a new day
  Future<void> _updateStreakForNewDay() async {
    final streakJson = storage.getHydrationStreak();
    if (streakJson == null) return;

    final streak = HydrationStreak.fromJson(jsonDecode(streakJson));

    // Check if goal was met yesterday
    final yesterdayScore = storage.getHydrationScoreToday();
    bool goalMetYesterday = false;

    if (yesterdayScore != null) {
      final score = HydrationScore.fromJson(jsonDecode(yesterdayScore));
      goalMetYesterday = score.score >= 80; // 80% completion = goal met
    }

    if (goalMetYesterday) {
      // Increment streak
      streak.currentStreak += 1;
      if (streak.currentStreak > streak.longestStreak) {
        streak.longestStreak = streak.currentStreak;
      }
    } else {
      // Reset streak if goal wasn't met
      if (streak.currentStreak > 0) {
        // Only reset if we were on a streak
        streak.currentStreak = 0;
      }
    }

    // Record today's date as a streak date
    streak.streakDates.add(DateTime.now());

    // Keep only last 365 days
    if (streak.streakDates.length > 365) {
      streak.streakDates.removeAt(0);
    }

    await storage.saveHydrationStreak(jsonEncode(streak.toJson()));
  }

  /// Schedule next daily reset at midnight
  void _scheduleNextReset() {
    _resetTimer?.cancel();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    final durationUntilReset = tomorrow.difference(now);

    _resetTimer = Timer(durationUntilReset, () {
      checkAndReset().then((_) {
        _scheduleNextReset(); // Schedule next reset
      });
    });
  }

  /// Get daily logs for a specific date
  Future<List<Map<String, dynamic>>> getDailyLogs(DateTime date) async {
    final dateStr = _getDateString(date);
    final dateNow = _getDateString(DateTime.now());

    List<String> logsJson;
    if (dateStr == dateNow) {
      logsJson = storage.getHydrationLogsToday();
    } else {
      logsJson = storage.getHydrationLogsForDate(date);
    }

    if (logsJson.isEmpty) return [];

    return logsJson.map((logJson) {
      final log = jsonDecode(logJson);
      return log as Map<String, dynamic>;
    }).toList();
  }

  /// Get total water consumed for a specific date
  Future<int> getTotalConsumedForDate(DateTime date) async {
    final logs = await getDailyLogs(date);
    int total = 0;
    for (var log in logs) {
      total += log['amountMl'] as int? ?? 0;
    }
    return total;
  }

  /// Get water consumption history for last N days
  Future<Map<String, int>> getHistoryLastNDays(int days) async {
    final history = <String, int>{};

    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = _getDateString(date);
      final consumed = await getTotalConsumedForDate(date);
      history[dateStr] = consumed;
    }

    return history;
  }

  /// Get average daily consumption for last N days
  Future<int> getAverageDailyConsumption(int days) async {
    final history = await getHistoryLastNDays(days);
    if (history.isEmpty) return 0;

    int total = 0;
    for (var value in history.values) {
      total += value;
    }

    return (total / days).toInt();
  }

  /// Get daily statistics
  Future<Map<String, dynamic>> getDailyStatistics(DateTime date) async {
    final dateStr = _getDateString(date);
    final dateNow = _getDateString(DateTime.now());

    String? scoreJson;
    if (dateStr == dateNow) {
      scoreJson = storage.getHydrationScoreToday();
    } else {
      scoreJson = storage.getLastHydrationScore();
    }

    final consumed = await getTotalConsumedForDate(date);

    final goalJson = storage.getHydrationGoal();
    int dailyGoal = 2000; // Default goal
    if (goalJson != null) {
      final goal = jsonDecode(goalJson);
      dailyGoal = goal['dailyGoalMl'] as int? ?? 2000;
    }

    int score = 0;
    if (scoreJson != null) {
      final scoreData = jsonDecode(scoreJson);
      score = scoreData['score'] as int? ?? 0;
    }

    final hydrationLevel = _calculationService.calculateHydrationLevel(
      consumedMl: consumed,
      goalMl: dailyGoal,
    );

    return {
      'date': dateStr,
      'consumed': consumed,
      'goal': dailyGoal,
      'score': score,
      'hydrationLevel': hydrationLevel,
      'goalMet': hydrationLevel >= 100,
      'glassesConsumed': (consumed / 250).round(),
    };
  }

  /// Archive historical data periodically
  Future<void> archiveOldData() async {
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30));

    // Use storage service to remove old historical logs
    await storage.removeOldHistoryLogs(30);
  }

  /// Clear all hydration data (for testing/reset)
  Future<void> clearAllData() async {
    final keys = storage.getAllKeys();

    for (var key in keys) {
      if (key.startsWith('hydration_') || key.startsWith('reminder_')) {
        await storage.removeKey(key);
      }
    }
  }

  /// Dispose reset service
  void dispose() {
    _resetTimer?.cancel();
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get days since app started
  Future<int> getDaysSinceStart() async {
    final startDateStr = storage.getAppStartDate();

    if (startDateStr == null) {
      return 0;
    }

    try {
      final startDate = DateTime.parse(startDateStr);
      return DateTime.now().difference(startDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  /// Record app start date (if first time)
  Future<void> recordAppStartDate() async {
    final startDateStr = storage.getAppStartDate();

    if (startDateStr == null) {
      await storage.saveAppStartDate(DateTime.now().toIso8601String());
    }
  }
}
