import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:solo_leveling/models/hydration_goal.dart';
import 'package:solo_leveling/models/hydration_log.dart';
import 'package:solo_leveling/models/notification_event.dart';
import 'notification_service.dart';
import 'hydration_calculation_service.dart';

class AdaptiveReminderService {
  static final AdaptiveReminderService _instance =
      AdaptiveReminderService._internal();

  factory AdaptiveReminderService() {
    return _instance;
  }

  AdaptiveReminderService._internal();

  Timer? _reminderTimer;
  final NotificationService _notificationService = NotificationService();
  final HydrationCalculationService _calculationService =
      HydrationCalculationService();

  static const int _baseReminderIntervalMinutes = 60;
  static const int _minReminderIntervalMinutes = 30;
  static const int _maxReminderIntervalMinutes = 240;

  /// Initialize reminder system
  Future<void> initializeReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final isReminderPaused = prefs.getBool('reminder_paused') ?? false;

    if (!isReminderPaused) {
      await startSmartReminders();
    }
  }

  /// Start smart adaptive reminders
  Future<void> startSmartReminders() async {
    _reminderTimer?.cancel();

    // Calculate next reminder time
    final nextReminderDuration = await _calculateNextReminderTime();

    _reminderTimer =
        Timer(nextReminderDuration, () => _sendAdaptiveReminder());
  }

  /// Send adaptive reminder based on user behavior
  Future<void> _sendAdaptiveReminder() async {
    final prefs = await SharedPreferences.getInstance();

    // Load current hydration data
    final goalJson = prefs.getString('hydration_goal');
    final logsJson = prefs.getStringList('hydration_logs_today') ?? [];

    if (goalJson == null) {
      // No goal set, don't send reminder
      return;
    }

    final goal = HydrationGoal.fromJson(jsonDecode(goalJson));
    int totalConsumedMl = 0;

    for (var logJson in logsJson) {
      final log = HydrationLog.fromJson(jsonDecode(logJson));
      totalConsumedMl += log.amountMl.toInt();
    }

    // Determine reminder type based on time and consumption
    await _determineAndSendReminder(
      goal: goal,
      currentConsumption: totalConsumedMl,
      logsToday: logsJson.length,
    );

    // Record notification event
    await _recordNotificationEvent(
      type: 'reminder',
      status: 'sent',
    );

    // Schedule next reminder
    await startSmartReminders();
  }

  /// Determine which type of reminder to send
  Future<void> _determineAndSendReminder({
    required HydrationGoal goal,
    required int currentConsumption,
    required int logsToday,
  }) async {
    final now = DateTime.now();
    final hydrationLevel = _calculationService.calculateHydrationLevel(
      consumedMl: currentConsumption,
      goalMl: goal.dailyGoalMl.toInt(),
    );

    // Check if user is behind schedule
    final minutesSinceWakeUp = _minutesSinceWakeUp(goal.wakeUpTime.hour);
    final minutesBeforeSleep = _minutesBeforeSleep(goal.sleepTime.hour);

    if (minutesSinceWakeUp < 0 || minutesBeforeSleep < 0) {
      // Outside wake/sleep window
      return;
    }

    // Determine notification type
    if (currentConsumption >= goal.dailyGoalMl) {
      // Goal already reached
      return;
    }

    if (hydrationLevel < 25) {
      // Very low hydration - urgent reminder
      await _notificationService.sendHydrationReminder(
        title: '💧 Time to Hydrate!',
        body:
            'You haven\'t consumed much water yet. Let\'s get started! Drink a glass now.',
        notificationId: _generateNotificationId(),
        payload: 'urgent_reminder',
      );
    } else if (hydrationLevel < 50) {
      // Below halfway - encouraging reminder
      await _notificationService.sendHydrationReminder(
        title: '💧 Keep the Momentum!',
        body:
            'You\'re ${hydrationLevel}% of the way. Have another glass of water!',
        notificationId: _generateNotificationId(),
        payload: 'progress_reminder',
      );
    } else if (hydrationLevel < 80) {
      // Getting close - motivational reminder
      await _notificationService.sendHydrationReminder(
        title: '💧 Almost There!',
        body:
            'You\'re ${hydrationLevel}% done. Just a few more glasses to reach your goal!',
        notificationId: _generateNotificationId(),
        payload: 'motivational_reminder',
      );
    } else {
      // Very close - final push
      await _notificationService.sendHydrationReminder(
        title: '💧 Final Push!',
        body: 'You\'re so close! Just ${goal.dailyGoalMl - currentConsumption}ml more!',
        notificationId: _generateNotificationId(),
        payload: 'final_reminder',
      );
    }
  }

  /// Calculate adaptive reminder interval
  Future<Duration> _calculateNextReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final goalJson = prefs.getString('hydration_goal');

    if (goalJson == null) {
      // Default to 1 hour if no goal
      return const Duration(minutes: _baseReminderIntervalMinutes);
    }

    final goal = HydrationGoal.fromJson(jsonDecode(goalJson));
    final logsJson = prefs.getStringList('hydration_logs_today') ?? [];

    int totalConsumedMl = 0;
    for (var logJson in logsJson) {
      final log = HydrationLog.fromJson(jsonDecode(logJson));
      totalConsumedMl += log.amountMl.toInt();
    }

    // Get user's base reminder interval preference
    int baseInterval = goal.reminderIntervalMinutes ?? _baseReminderIntervalMinutes;

    // Adjust based on consumption pattern
    double adjustmentFactor = _calculateAdjustmentFactor(
      consumedMl: totalConsumedMl,
      goalMl: goal.dailyGoalMl.toInt(),
      logsCount: logsJson.length,
    );

    int adaptiveInterval = (baseInterval.toDouble() * adjustmentFactor).toInt();

    // Keep within min/max bounds
    if (adaptiveInterval < _minReminderIntervalMinutes) {
      adaptiveInterval = _minReminderIntervalMinutes;
    }
    if (adaptiveInterval > _maxReminderIntervalMinutes) {
      adaptiveInterval = _maxReminderIntervalMinutes;
    }

    return Duration(minutes: adaptiveInterval);
  }

  /// Calculate adjustment factor for reminder frequency
  double _calculateAdjustmentFactor({
    required int consumedMl,
    required int goalMl,
    required int logsCount,
  }) {
    // If no logs yet, increase frequency (more urgent reminders)
    if (logsCount == 0) {
      return 0.7; // 70% of base interval
    }

    final hydrationLevel = (consumedMl.toDouble() / goalMl.toDouble()) * 100;

    // More frequent reminders for low consumption
    if (hydrationLevel < 25) {
      return 0.6; // 60% of base interval (more frequent)
    } else if (hydrationLevel < 50) {
      return 0.8; // 80% of base interval
    } else if (hydrationLevel < 75) {
      return 1.0; // Normal interval
    } else {
      return 1.2; // 120% of base interval (less frequent as goal nears)
    }
  }

  /// Check for notification fatigue
  Future<bool> shouldSuppressReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final recentNotifications =
        prefs.getStringList('recent_notifications') ?? [];

    // Check if more than 3 notifications in last 30 minutes
    final thirtyMinutesAgo =
        DateTime.now().subtract(const Duration(minutes: 30));

    int count = 0;
    for (var notifJson in recentNotifications) {
      try {
        final notif = NotificationEvent.fromJson(jsonDecode(notifJson));
        if (notif.sentTime.isAfter(thirtyMinutesAgo)) {
          count++;
        }
      } catch (e) {
        continue;
      }
    }

    return count >= 3; // Suppress if too many recent notifications
  }

  /// Pause reminders for specified duration
  Future<void> pauseReminders({
    required Duration duration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_paused', true);
    final resumeTime = DateTime.now().add(duration);
    await prefs.setString('reminder_resume_time', resumeTime.toIso8601String());

    _reminderTimer?.cancel();

    // Schedule resume
    Timer(duration, () => resumeReminders());
  }

  /// Resume reminders
  Future<void> resumeReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_paused', false);
    await prefs.remove('reminder_resume_time');

    await startSmartReminders();
  }

  /// Check if reminders are paused and resume if needed
  Future<void> checkAndAutoResume() async {
    final prefs = await SharedPreferences.getInstance();
    final isPaused = prefs.getBool('reminder_paused') ?? false;

    if (!isPaused) return;

    final resumeTimeStr = prefs.getString('reminder_resume_time');
    if (resumeTimeStr == null) return;

    final resumeTime = DateTime.parse(resumeTimeStr);
    if (DateTime.now().isAfter(resumeTime)) {
      await resumeReminders();
    }
  }

  /// Record notification event for analytics
  Future<void> _recordNotificationEvent({
    required String type,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final event = NotificationEvent(
      id: '${type}_${DateTime.now().millisecondsSinceEpoch}',
      sentTime: DateTime.now(),
      action: status,
    );

    final recentNotifications =
        prefs.getStringList('recent_notifications') ?? [];

    // Keep only last 20 notifications
    if (recentNotifications.length >= 20) {
      recentNotifications.removeAt(0);
    }

    recentNotifications.add(jsonEncode(event.toJson()));
    await prefs.setStringList('recent_notifications', recentNotifications);
  }

  /// Dispose reminder service
  void dispose() {
    _reminderTimer?.cancel();
  }

  int _minutesSinceWakeUp(int wakeHour) {
    final now = DateTime.now();
    final wakeTime = DateTime(now.year, now.month, now.day, wakeHour, 0);

    if (now.isBefore(wakeTime)) {
      return -1; // Not yet awake
    }

    return now.difference(wakeTime).inMinutes;
  }

  int _minutesBeforeSleep(int sleepHour) {
    final now = DateTime.now();
    var sleepTime = DateTime(now.year, now.month, now.day, sleepHour, 0);

    if (now.isAfter(sleepTime)) {
      // Sleep time is tomorrow
      sleepTime = sleepTime.add(const Duration(days: 1));
    }

    if (now.isAfter(sleepTime)) {
      return -1; // Past sleep time
    }

    return sleepTime.difference(now).inMinutes;
  }

  int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.toInt() % 100000;
  }
}
