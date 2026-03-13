import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    if (Platform.isIOS) {
      await _requestIOSPermissions();
    }
  }

  Future<void> _requestIOSPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    print('Notification tapped: ${notificationResponse.payload}');
  }

  /// Send hydration reminder notification
  Future<void> sendHydrationReminder({
    required String title,
    required String body,
    required int notificationId,
    String? payload,
    bool useSound = true,
    bool useVibration = true,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'hydration_reminders',
      'Hydration Reminders',
      channelDescription: 'Smart water drinking reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: const Color.fromARGB(255, 0, 217, 255),
      showProgress: false,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Send achievement unlock notification
  Future<void> sendAchievementNotification({
    required String achievementName,
    required String achievementDescription,
    required int xpReward,
    required int notificationId,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'hydration_achievements',
      'Achievement Unlocked',
      channelDescription: 'Hydration achievement notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: const Color.fromARGB(255, 255, 215, 0),
      showProgress: false,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _notificationsPlugin.show(
      notificationId,
      '🎉 Achievement Unlocked!',
      '$achievementName: $achievementDescription (+$xpReward XP)',
      notificationDetails,
      payload: 'achievement:$achievementName',
    );
  }

  /// Send goal reached notification
  Future<void> sendGoalReachedNotification({
    required int consumedMl,
    required int goalMl,
    required int notificationId,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'hydration_goals',
      'Daily Goal Updates',
      channelDescription: 'Hydration goal notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: const Color.fromARGB(255, 0, 217, 255),
      showProgress: false,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _notificationsPlugin.show(
      notificationId,
      '💧 Daily Goal Reached!',
      'You\'ve consumed $consumedMl ml out of $goalMl ml. Great job!',
      notificationDetails,
      payload: 'goal_reached',
    );
  }

  /// Send streak milestone notification
  Future<void> sendStreakMilestoneNotification({
    required int streakDays,
    required int notificationId,
  }) async {
    final milestone = _getStreakMilestone(streakDays);

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'hydration_streaks',
      'Streak Milestones',
      channelDescription: 'Hydration streak milestone notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: const Color.fromARGB(255, 0, 217, 255),
      showProgress: false,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _notificationsPlugin.show(
      notificationId,
      '🔥 Streak Milestone!',
      '$milestone You\'ve stayed hydrated for $streakDays days!',
      notificationDetails,
      payload: 'streak:$streakDays',
    );
  }

  /// Send motivation notification for low water intake
  Future<void> sendMotivationNotification({
    required int currentMl,
    required int goalMl,
    required int notificationId,
  }) async {
    final percentage = ((currentMl / goalMl) * 100).toInt();
    final message = _getMotivationMessage(percentage);

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'hydration_reminders',
      'Hydration Reminders',
      channelDescription: 'Smart water drinking reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: const Color.fromARGB(255, 0, 217, 255),
      showProgress: false,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _notificationsPlugin.show(
      notificationId,
      'Stay Hydrated! 💧',
      message,
      notificationDetails,
      payload: 'motivation:$percentage',
    );
  }

  /// Cancel a notification by ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  String _getMotivationMessage(int percentage) {
    if (percentage == 0) {
      return 'Time to start your hydration journey! Drink some water now.';
    } else if (percentage < 25) {
      return 'You\'re just starting! Keep the momentum going. Try a glass of water.';
    } else if (percentage < 50) {
      return 'You\'re making progress! About halfway there. Have some water.';
    } else if (percentage < 75) {
      return 'Great! You\'re 3/4 of the way. A few more glasses to go!';
    } else if (percentage < 100) {
      return 'Almost there! Just a bit more to reach your daily goal.';
    } else {
      return 'Goal achieved! But stay hydrated throughout the day.';
    }
  }

  String _getStreakMilestone(int days) {
    if (days == 7) return '🌟 One Week!';
    if (days == 14) return '⭐ Two Weeks!';
    if (days == 30) return '🌠 One Month!';
    if (days == 100) return '💫 100 Days!';
    if (days == 365) return '✨ One Year!';
    return '🎯';
  }
}
