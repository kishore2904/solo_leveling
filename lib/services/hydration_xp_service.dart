import 'dart:convert';
import 'package:solo_leveling/models/hydration_log.dart';
import 'package:solo_leveling/models/hydration_goal.dart';
import 'package:solo_leveling/models/hydration_streak.dart';
import 'storage_service.dart';

/// Service to calculate and award XP based on hydration achievements
class HydrationXpService {
  static final HydrationXpService _instance = HydrationXpService._internal();
  final storage = StorageService();

  factory HydrationXpService() {
    return _instance;
  }

  HydrationXpService._internal();

  /// Calculate XP reward for reaching daily goal
  int calculateDailyGoalXp({
    required int consumedMl,
    required int dailyGoalMl,
  }) {
    final percentage = (consumedMl / dailyGoalMl * 100).clamp(0, 200).toInt();

    if (percentage >= 100) {
      return 75; // Goal exceeded
    } else if (percentage >= 80) {
      return 50; // Goal reached (80%+)
    }
    return 0; // Goal not reached
  }

  /// Calculate XP bonus for no ignored reminders
  int calculateReminderBonusXp({
    required int ignoreCount,
  }) {
    // No reminders ignored = +20 XP bonus
    return ignoreCount == 0 ? 20 : 0;
  }

  /// Calculate XP for perfect timing on logs (within 30min of reminder)
  int calculateTimingBonusXp({
    required List<HydrationLog> logs,
    required int reminderIntervalMinutes,
  }) {
    int timingBonus = 0;

    for (var log in logs) {
      // Check if log is within 30 minutes of reminder schedule
      // Reminders on 60min interval (example), so check if log time aligns
      final logMinutes = log.timestamp.hour * 60 + log.timestamp.minute;
      final intervalMinutes = reminderIntervalMinutes;

      // Check if log is within ±30 min of expected reminder time
      final isWithinWindow = logMinutes % intervalMinutes >= (intervalMinutes - 30) ||
          logMinutes % intervalMinutes <= 30;

      if (isWithinWindow) {
        timingBonus += 10;
      }
    }

    return timingBonus;
  }

  /// Calculate XP for streak milestones
  int calculateStreakMilestoneXp({
    required int previousStreak,
    required int currentStreak,
  }) {
    // Award bonus XP when reaching certain milestones
    final milestones = {
      7: 100,
      14: 150,
      30: 250,
      100: 500,
      365: 1000,
    };

    for (var milestone in milestones.entries) {
      if (previousStreak < milestone.key && currentStreak >= milestone.key) {
        return milestone.value;
      }
    }

    return 0; // No milestone reached
  }

  /// Award XP for completing daily goal and return total XP awarded
  Future<int> awardDailyGoalXp({
    required int consumedMl,
    required int dailyGoalMl,
  }) async {
    final xpReward = calculateDailyGoalXp(
      consumedMl: consumedMl,
      dailyGoalMl: dailyGoalMl,
    );

    if (xpReward > 0) {
      await storage.addHydrationXpToday(xpReward);
      await storage.addHydrationTotalXp(xpReward);
    }

    return xpReward;
  }

  /// Award XP for reminder responsiveness
  Future<int> awardReminderBonusXp({
    required int ignoreCount,
  }) async {
    final xpReward = calculateReminderBonusXp(ignoreCount: ignoreCount);

    if (xpReward > 0) {
      await storage.addHydrationXpToday(xpReward);
      await storage.addHydrationTotalXp(xpReward);
    }

    return xpReward;
  }

  /// Award XP for perfect timing on logs
  Future<int> awardTimingBonusXp({
    required List<HydrationLog> logs,
    required int reminderIntervalMinutes,
  }) async {
    final xpReward = calculateTimingBonusXp(
      logs: logs,
      reminderIntervalMinutes: reminderIntervalMinutes,
    );

    if (xpReward > 0) {
      await storage.addHydrationXpToday(xpReward);
      await storage.addHydrationTotalXp(xpReward);
    }

    return xpReward;
  }

  /// Award XP for streak milestones
  Future<int> awardStreakMilestoneXp({
    required int previousStreak,
    required int currentStreak,
  }) async {
    final xpReward = calculateStreakMilestoneXp(
      previousStreak: previousStreak,
      currentStreak: currentStreak,
    );

    if (xpReward > 0) {
      await storage.addHydrationXpToday(xpReward);
      await storage.addHydrationTotalXp(xpReward);
    }

    return xpReward;
  }

  /// Get total XP earned from hydration today
  int getTodayXp() {
    return storage.getHydrationXpToday();
  }

  /// Get total XP earned from hydration (lifetime)
  int getTotalXp() {
    return storage.getHydrationTotalXp();
  }

  /// Get XP breakdown for today (formatted for display)
  Map<String, int> getTodayXpBreakdown({
    required int consumedMl,
    required int dailyGoalMl,
  }) {
    return {
      'goal': calculateDailyGoalXp(
        consumedMl: consumedMl,
        dailyGoalMl: dailyGoalMl,
      ),
      'total': getTodayXp(),
    };
  }
}
