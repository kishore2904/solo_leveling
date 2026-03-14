import 'dart:convert';
import 'package:solo_leveling/models/achievement.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class AchievementUnlockService {
  static final AchievementUnlockService _instance =
      AchievementUnlockService._internal();

  factory AchievementUnlockService() {
    return _instance;
  }

  AchievementUnlockService._internal();

  final NotificationService _notificationService = NotificationService();
  final storage = StorageService();

  /// Initialize achievements for a new user
  Future<void> initializeAchievements() async {
    final achievementsJson = storage.getAchievements();

    if (achievementsJson == null) {
      // Create all achievements in locked state
      final achievements = _createDefaultAchievements();
      await storage.saveAchievements(jsonEncode(achievements));
    }
  }

  /// Check and unlock achievements based on current hydration state
  Future<List<String>> checkAndUnlockAchievements({
    required int totalConsumedMl,
    required int dailyGoalMl,
    required int currentStreak,
    required int totalDaysTracked,
    required int totalWaterIntakeMl,
    required List<DateTime> loggingDates,
  }) async {
    final achievementsJson = storage.getAchievements();
    final unlockedNow = <String>[];

    if (achievementsJson == null) {
      await initializeAchievements();
      return unlockedNow;
    }

    final achievementsList = jsonDecode(achievementsJson) as List;
    final achievements =
        achievementsList.map((a) => Achievement.fromJson(a)).toList();

    // Check each achievement
    bool saveNeeded = false;

    for (var achievement in achievements) {
      if (achievement.isUnlocked) continue;

      final shouldUnlock = _checkAchievementCondition(
        achievement.id,
        totalConsumedMl: totalConsumedMl,
        dailyGoalMl: dailyGoalMl,
        currentStreak: currentStreak,
        totalDaysTracked: totalDaysTracked,
        totalWaterIntakeMl: totalWaterIntakeMl,
        loggingDates: loggingDates,
      );

      if (shouldUnlock) {
        achievement.isUnlocked = true;
        achievement.unlockedAt = DateTime.now();
        unlockedNow.add(achievement.id);
        saveNeeded = true;

        // Send notification
        await _notificationService.sendAchievementNotification(
          achievementName: achievement.title,
          achievementDescription: achievement.description,
          xpReward: 10,
          notificationId: _generateNotificationId(),
        );
      }
    }

    if (saveNeeded) {
      await storage.saveAchievements(
        jsonEncode(achievements.map((a) => a.toJson()).toList()),
      );
    }

    return unlockedNow;
  }

  /// Check if achievement condition is met
  bool _checkAchievementCondition(
    String achievementId, {
    required int totalConsumedMl,
    required int dailyGoalMl,
    required int currentStreak,
    required int totalDaysTracked,
    required int totalWaterIntakeMl,
    required List<DateTime> loggingDates,
  }) {
    switch (achievementId) {
      case 'first_drop':
        // Log water for the first time
        return totalConsumedMl > 0;

      case 'morning_hydrator':
        // Log water before 9 AM
        final now = DateTime.now();
        return now.hour < 9 && totalConsumedMl > 0;

      case 'hydration_starter':
        // Consume 500ml in a day
        return totalConsumedMl >= 500;

      case 'weekly_warrior':
        // Maintain a 7-day streak
        return currentStreak >= 7;

      case 'hydration_hero':
        // Consume 10 liters total
        return totalWaterIntakeMl >= 10000;

      case 'water_master':
        // Maintain a 30-day streak
        return currentStreak >= 30;

      case 'consistency_king':
        // Log water for 14 consecutive days
        return currentStreak >= 14;

      case 'night_owl':
        // Log water after 9 PM
        final now = DateTime.now();
        return now.hour >= 21 && totalConsumedMl > 0;

      case 'never_ignore':
        // Complete goal for 5 consecutive days
        return currentStreak >= 5 && totalConsumedMl >= (dailyGoalMl * 0.8);

      case 'smart_pacer':
        // Log water 5 or more times in a day
        final logsToday = loggingDates
            .where((date) =>
                date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day)
            .length;
        return logsToday >= 5;

      default:
        return false;
    }
  }

  /// Get all achievements with unlock status
  Future<List<Achievement>> getAllAchievements() async {
    final achievementsJson = storage.getAchievements();

    if (achievementsJson == null) {
      await initializeAchievements();
      return _createDefaultAchievements()
          .map((a) => Achievement.fromJson(a))
          .toList();
    }

    final achievementsList = jsonDecode(achievementsJson) as List;
    return achievementsList.map((a) => Achievement.fromJson(a)).toList();
  }

  /// Get total XP from achievements
  Future<int> getTotalAchievementXP() async {
    final achievements = await getAllAchievements();
    final totalXp = achievements.fold<int>(0, (sum, a) => sum + 10);
    return totalXp;
  }

  /// Get achievement by ID
  Future<Achievement?> getAchievementById(String id) async {
    final achievements = await getAllAchievements();
    try {
      return achievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Reset all achievements (for testing)
  Future<void> resetAllAchievements() async {
    final achievements = _createDefaultAchievements();
    await storage.saveAchievements(jsonEncode(achievements));
  }

  /// Create default achievements
  List<Map<String, dynamic>> _createDefaultAchievements() {
    return [
      Achievement(
        id: 'first_drop',
        title: 'First Drop',
        description: 'Log water for the first time',
        icon: '🔷',
        category: 'beginner',
        requirement: 1,
        isUnlocked: false,
        unlockedAt: null,
      ).toJson(),
      Achievement(
        id: 'morning_hydrator',
        title: 'Morning Hydrator',
        description: 'Log water before 9 AM',
        icon: '☀️',
        category: 'timing',
        requirement: 1,
        isUnlocked: false,
        unlockedAt: null,
      ).toJson(),
      Achievement(
        id: 'hydration_starter',
        title: 'Hydration Starter',
        description: 'Consume 500ml of water in a day',
        icon: '💧',
        category: 'progress',
        requirement: 500,
        isUnlocked: false,
        unlockedAt: null,
      ).toJson(),
      Achievement(
        id: 'weekly_warrior',
        title: 'Weekly Warrior',
        description: 'Maintain a 7-day hydration streak',
        icon: '🔥',
        category: 'streak',
        requirement: 7,
        isUnlocked: false,
        unlockedAt: null,
      ).toJson(),
      Achievement(
        id: 'hydration_hero',
        title: 'Hydration Hero',
        description: 'Consume 10 liters of water total',
        icon: '💪',
        category: 'milestone',
        requirement: 10000,
        isUnlocked: false,
        unlockedAt: null,
      ).toJson(),
      Achievement(
        id: 'water_master',
        title: 'Water Master',
        description: 'Maintain a 30-day hydration streak',
        icon: '👑',
        category: 'streak',
        requirement: 30,
        isUnlocked: false,
        unlockedAt: null,
      ).toJson(),
      Achievement(
        id: 'consistency_king',
        title: 'Consistency King',
        description: 'Log water for 14 consecutive days',
        icon: '🏅',
        category: 'consistency',
        requirement: 14,
        isUnlocked: false,
        unlockedAt: null,
      ).toJson(),
      Achievement(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Log water after 9 PM',
        icon: '🌙',
        category: 'timing',
        requirement: 1,
        isUnlocked: false,
        unlockedAt: null,
      ).toJson(),
      Achievement(
        id: 'never_ignore',
        title: 'Never Ignore',
        description: 'Complete daily goal for 5 consecutive days',
        icon: '⭐',
        category: 'completion',
        requirement: 5,
        isUnlocked: false,
        unlockedAt: null,
      ).toJson(),
      Achievement(
        id: 'smart_pacer',
        title: 'Smart Pacer',
        description: 'Log water 5 or more times in a single day',
        icon: '⚡',
        category: 'frequency',
        requirement: 5,
        isUnlocked: false,
        unlockedAt: null,
      ).toJson(),
    ];
  }

  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.toInt() % 100000;
  }
}
