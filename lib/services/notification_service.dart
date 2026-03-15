import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const int testNotificationIdStart = 50000;
  static const int testNotificationIdEnd = 50059; // 60 notifications max

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Callback for handling notification taps with navigation
  Function(String? payload)? _notificationTapCallback;

  Future<void> initialize() async {
    // Initialize timezone
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      defaultPresentSound: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannels();
      print('✅ Notification channels created for Android');
    }

    // Request permissions for iOS
    if (Platform.isIOS) {
      await _requestIOSPermissions();
      print('✅ iOS permissions requested');
    }
  }

  /// Create Android notification channels
  Future<void> _createAndroidNotificationChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      print('⚠️ Android plugin not available');
      return;
    }

    try {
      // Hydration Reminders Channel
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          'hydration_reminders',
          'Hydration Reminders',
          description: 'Smart water drinking reminders',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
        ),
      );
      print('  ✓ Created hydration_reminders channel');

      // Achievements Channel
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          'hydration_achievements',
          'Achievement Unlocked',
          description: 'Hydration achievement notifications',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
        ),
      );
      print('  ✓ Created hydration_achievements channel');

      // Goals Channel
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          'hydration_goals',
          'Daily Goal Updates',
          description: 'Hydration goal notifications',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
        ),
      );
      print('  ✓ Created hydration_goals channel');

      // Streaks Channel
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          'hydration_streaks',
          'Streak Milestones',
          description: 'Hydration streak milestone notifications',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
        ),
      );
      print('  ✓ Created hydration_streaks channel');

      // Custom Tasks Channel
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          'custom_tasks',
          'Task Reminders',
          description: 'Custom task reminder notifications',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
        ),
      );
      print('  ✓ Created custom_tasks channel');
    } catch (e) {
      print('⚠️ Error creating channels: $e');
    }
  }

  /// Request Android 12+ permission for exact alarm scheduling
  Future<void> _requestAndroidSchedulePermission() async {
    if (!Platform.isAndroid) return;
    
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      try {
        final granted = await androidPlugin.requestExactAlarmsPermission();
        if (granted == true) {
          print('✅ Exact alarm permission granted');
        } else {
          print('⚠️ Exact alarm permission denied');
        }
      } catch (e) {
        print('⚠️ Could not request exact alarm permission: $e');
      }
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

  /// Set callback for handling notification taps
  void setNotificationTapCallback(Function(String? payload)? callback) {
    _notificationTapCallback = callback;
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap with callback
    print('Notification tapped: ${notificationResponse.payload}');
    
    // Call the callback if set
    if (_notificationTapCallback != null) {
      _notificationTapCallback!(notificationResponse.payload);
    }
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
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
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
      id: notificationId,
      title: '🎉 Achievement Unlocked!',
      body: '$achievementName: $achievementDescription (+$xpReward XP)',
      notificationDetails: notificationDetails,
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
      id: notificationId,
      title: '💧 Daily Goal Reached!',
      body: 'You\'ve consumed $consumedMl ml out of $goalMl ml. Great job!',
      notificationDetails: notificationDetails,
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
      id: notificationId,
      title: '🔥 Streak Milestone!',
      body: '$milestone You\'ve stayed hydrated for $streakDays days!',
      notificationDetails: notificationDetails,
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
      id: notificationId,
      title: 'Stay Hydrated! 💧',
      body: message,
      notificationDetails: notificationDetails,
      payload: 'motivation:$percentage',
    );
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

  /// Cancel a notification by ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Start periodic drinking water reminders every 2 minutes (for testing)
  /// Works even when phone is locked
  Future<void> startPeriodicDrinkingReminder() async {
    try {
      print('═' * 80);
      print('🚀 STARTING PERIODIC DRINKING WATER REMINDER TEST');
      print('═' * 80);
      
      // Request Android permissions first
      await _requestAndroidSchedulePermission();
      print('─' * 80);
      
      // Clear ALL notifications (bypasses corrupted cache)
      print('🧹 Clearing all old notifications...');
      try {
        await _notificationsPlugin.cancelAll();
        print('✅ All old notifications cleared');
      } catch (e) {
        print('⚠️  Could not clear all - continuing anyway: $e');
      }
      print('─' * 80);

      // Use timezone-aware current time
      final localTz = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime.now(localTz);
      print('⏰ Current Time: ${_formatDateTime(now)}');
      print('📍 Timezone: Asia/Kolkata');
      print('📱 Testing 10 notifications every 2 minutes');
      print('🔔 Importance: MAX (Like WhatsApp)');
      print('⏱️ Schedule Mode: Alarm Clock (Bypasses battery optimization)');
      print('─' * 80);

      // First, send an immediate test notification
      print('📤 Sending test notification NOW to verify channel works...');
      await sendHydrationReminder(
        title: '💧 Test Notification',
        body: 'If you see this, notifications are working!',
        notificationId: 49999,
        payload: 'test:immediate',
      );
      print('✅ Immediate test notification sent!');
      print('─' * 80);

      // Create notification details - keep it minimal for serialization
      final androidNotificationDetails = AndroidNotificationDetails(
        'hydration_reminders',
        'Hydration Reminders',
        channelDescription: 'Smart water drinking reminders',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
        enableLights: true,
        showProgress: false,
      );

      const iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      // Schedule 10 notifications, one every 2 minutes
      print('📋 SCHEDULING 10 NOTIFICATIONS:');
      int successCount = 0;
      
      for (int i = 0; i < 10; i++) {
        try {
          // Create the scheduled time by adding minutes to current time
          // This correctly maintains timezone information
          final minutesToAdd = (i + 1) * 2;
          final scheduledTime = tz.TZDateTime(
            localTz,
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute + minutesToAdd,
            now.second,
          );
          
          final notificationId = testNotificationIdStart + i;

          // Schedule with proper timezone handling
          await _notificationsPlugin.zonedSchedule(
            id: notificationId,
            title: '💧 Drink Water #${i + 1}',
            body: 'Time to hydrate! Stay healthy and refreshed.',
            scheduledDate: scheduledTime,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            matchDateTimeComponents: DateTimeComponents.time,
          );

          successCount++;
          final timeUntilNotification = scheduledTime.difference(now);
          final minutesFromNow = timeUntilNotification.inMinutes;
          final secondsFromNow = timeUntilNotification.inSeconds % 60;

          print(
            '   ${i + 1}️⃣ ID: $notificationId | Scheduled: ${_formatDateTime(scheduledTime)} | In: ${minutesFromNow}m ${secondsFromNow}s ✅',
          );
        } catch (e) {
          print('   ${i + 1}️⃣ ❌ Failed: $e');
          rethrow; // Log the full error
        }
      }

      print('─' * 80);
      print('✨ SUCCESS: $successCount/10 notifications scheduled!');
      print('📊 Summary:');
      print('   • Start: ${_formatDateTime(now)}');
      final endTime = tz.TZDateTime(
        localTz,
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute + 20,
        now.second,
      );
      print('   • End: ${_formatDateTime(endTime)}');
      print('   • Interval: Every 2 minutes');
      print('   • ✅ Will trigger even if app is closed');
      print('   • ✅ Will trigger even if phone is locked');
      print('   • 📌 Make sure battery optimization is DISABLED for this app');
      print('═' * 80);
      
      // Verify immediately
      await Future.delayed(const Duration(milliseconds: 500));
      await verifyPendingNotifications();
      
    } catch (e) {
      print('❌ ERROR: Failed to schedule reminder: $e');
      print('═' * 80);
    }
  }

  /// Stop periodic drinking water reminders
  Future<void> stopPeriodicDrinkingReminder() async {
    try {
      print('═' * 80);
      print('🛑 STOPPING PERIODIC DRINKING WATER REMINDER TEST');
      print('═' * 80);
      
      await _notificationsPlugin.cancelAll();
      
      print('✅ All notifications cancelled!');
      print('═' * 80);
    } catch (e) {
      print('❌ ERROR: Failed to cancel reminders: $e');
      print('═' * 80);
    }
  }

  /// Helper method to format DateTime with visual indicators
  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final dayName = _getDayName(dateTime.weekday);
    return '$dayName ${dateTime.day}/${dateTime.month}/${dateTime.year} $hour:$minute:$second';
  }

  /// Helper to get day name
  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Enhanced method to schedule notifications with highest reliability
  /// This uses exact alarm scheduling to ensure notifications work even when app is closed
  Future<void> scheduleNotificationWithExactAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
    String? payload,
  }) async {
    try {
      final androidNotificationDetails = AndroidNotificationDetails(
        channelId,
        'Scheduled Notifications',
        channelDescription: 'Important scheduled notifications',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
        enableLights: true,
        showProgress: false,
      );

      const iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: payload,
      );

      print('✅ Scheduled notification ID: $id at ${_formatDateTime(scheduledTime)}');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  /// Verify that test notifications are still scheduled
  Future<void> verifyPendingNotifications() async {
    try {
      final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();
      
      print('═' * 80);
      print('🔍 CHECKING PENDING NOTIFICATIONS');
      print('═' * 80);
      print('📊 Total pending notifications: ${pendingNotifications.length}');
      
      if (pendingNotifications.isEmpty) {
        print('⚠️  No pending notifications found!');
        print('   Possible issues:');
        print('   • Notifications were already fired');
        print('   • Battery optimization is blocking them');
        print('   • Permission not granted');
      } else {
        print('✅ Found pending notifications:');
        for (final notification in pendingNotifications) {
          if (notification.id >= testNotificationIdStart && 
              notification.id <= testNotificationIdEnd) {
            print('   • ID: ${notification.id} | Title: ${notification.title}');
          }
        }
      }
      
      print('═' * 80);
      print('💡 TIP: If no pending notifications found, check:');
      print('   1. Settings → Apps → Solo Leveling → Disable "Battery Optimization"');
      print('   2. Settings → Apps → Solo Leveling → Notifications → Allow all');
      print('   3. Settings → Do Not Disturb → Turn OFF');
      print('═' * 80);
    } catch (e) {
      print('❌ Error checking pending notifications: $e');
    }
  }
}
