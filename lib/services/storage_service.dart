import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for all local storage operations using SharedPreferences
class StorageService {
  static final StorageService _instance = StorageService._internal();
  late SharedPreferences _prefs;

  // Private constructor for singleton pattern
  StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  /// Initialize the storage service - call this in main.dart or app startup
  static Future<void> initialize() async {
    _instance._prefs = await SharedPreferences.getInstance();
  }

  // ============ STORAGE KEYS ============
  static const String _keyPlayerName = 'player_name';
  static const String _keyLastLoginDate = 'last_login_date';
  static const String _keyDailyStreak = 'daily_streak';
  static const String _keyTotalExperience = 'total_experience';
  static const String _keyPlayerLevel = 'player_level';
  static const String _keyMaxExperience = 'max_experience';
  static const String _keyHydrationGoal = 'hydration_goal';
  static const String _keyHydrationLogsToday = 'hydration_logs_today';
  static const String _keyHydrationStreak = 'hydration_streak';
  static const String _keyHydrationScoreToday = 'hydration_score_today';
  static const String _keyLastResetDate = 'last_reset_date';
  static const String _keyLastHydrationScore = 'last_hydration_score';
  static const String _keyAppStartDate = 'app_start_date';
  static const String _keyReminderPaused = 'reminder_paused';
  static const String _keyReminderResumeTime = 'reminder_resume_time';
  static const String _keyRecentNotifications = 'recent_notifications';
  static const String _keyAchievements = 'achievements';
  static const String _keyHydrationXpToday = 'hydration_xp_today';
  static const String _keyHydrationTotalXp = 'hydration_total_xp';
  static const String _keyLastHydrationXpReset = 'last_hydration_xp_reset';

  // ============ PLAYER DATA ============
  /// Save player name
  Future<bool> savePlayerName(String name) async {
    return await _prefs.setString(_keyPlayerName, name);
  }

  /// Get saved player name
  String? getPlayerName() {
    return _prefs.getString(_keyPlayerName);
  }

  // ============ DAILY STREAK ============
  /// Save last login date to track streaks
  Future<bool> saveLastLoginDate(String dateString) async {
    return await _prefs.setString(_keyLastLoginDate, dateString);
  }

  /// Get last login date
  String? getLastLoginDate() {
    return _prefs.getString(_keyLastLoginDate);
  }

  /// Save current daily streak count
  Future<bool> saveDailyStreak(int streakCount) async {
    return await _prefs.setInt(_keyDailyStreak, streakCount);
  }

  /// Get current daily streak count
  int getDailyStreak() {
    return _prefs.getInt(_keyDailyStreak) ?? 0;
  }

  // ============ EXPERIENCE & LEVEL ============
  /// Save total player experience
  Future<bool> saveTotalExperience(int totalXp) async {
    return await _prefs.setInt(_keyTotalExperience, totalXp);
  }

  /// Get total player experience
  int getTotalExperience() {
    return _prefs.getInt(_keyTotalExperience) ?? 0;
  }

  /// Save player level
  Future<bool> savePlayerLevel(int level) async {
    return await _prefs.setInt(_keyPlayerLevel, level);
  }

  /// Get player level
  int getPlayerLevel() {
    return _prefs.getInt(_keyPlayerLevel) ?? 1;
  }

  /// Save max experience for current level
  Future<bool> saveMaxExperience(int maxXp) async {
    return await _prefs.setInt(_keyMaxExperience, maxXp);
  }

  /// Get max experience for current level
  int getMaxExperience() {
    return _prefs.getInt(_keyMaxExperience) ?? 1000;
  }

  // ============ DAILY QUESTS ============
  /// Get quests data key for a specific date
  static String _getQuestKey(DateTime date) {
    return 'quests_${date.year}_${date.month}_${date.day}';
  }

  /// Save quest data for a specific date
  Future<bool> saveQuestData(DateTime date, String questsJson) async {
    final key = _getQuestKey(date);
    return await _prefs.setString(key, questsJson);
  }

  /// Get quest data for a specific date
  String? getQuestData(DateTime date) {
    final key = _getQuestKey(date);
    return _prefs.getString(key);
  }

  /// Clear quest data for a specific date
  Future<bool> clearQuestData(DateTime date) async {
    final key = _getQuestKey(date);
    return await _prefs.remove(key);
  }

  // ============ HYDRATION GOAL ============
  /// Save hydration goal configuration
  Future<bool> saveHydrationGoal(String goalJson) async {
    return await _prefs.setString(_keyHydrationGoal, goalJson);
  }

  /// Get hydration goal configuration
  String? getHydrationGoal() {
    return _prefs.getString(_keyHydrationGoal);
  }

  // ============ HYDRATION LOGS ============
  /// Save today's hydration logs
  Future<bool> saveHydrationLogsToday(List<String> logsJson) async {
    return await _prefs.setStringList(_keyHydrationLogsToday, logsJson);
  }

  /// Get today's hydration logs
  List<String> getHydrationLogsToday() {
    return _prefs.getStringList(_keyHydrationLogsToday) ?? [];
  }

  /// Save hydration logs for a specific date (historical data)
  Future<bool> saveHydrationLogsForDate(DateTime date, List<String> logsJson) async {
    final key = _getHistoryLogKey(date);
    return await _prefs.setStringList(key, logsJson);
  }

  /// Get hydration logs for a specific date
  List<String> getHydrationLogsForDate(DateTime date) {
    final key = _getHistoryLogKey(date);
    return _prefs.getStringList(key) ?? [];
  }

  /// Clear today's hydration logs
  Future<bool> clearHydrationLogsToday() async {
    return await _prefs.remove(_keyHydrationLogsToday);
  }

  // ============ HYDRATION STREAK ============
  /// Save hydration streak data
  Future<bool> saveHydrationStreak(String streakJson) async {
    return await _prefs.setString(_keyHydrationStreak, streakJson);
  }

  /// Get hydration streak data
  String? getHydrationStreak() {
    return _prefs.getString(_keyHydrationStreak);
  }

  // ============ HYDRATION SCORE ============
  /// Save today's hydration score
  Future<bool> saveHydrationScoreToday(String scoreJson) async {
    return await _prefs.setString(_keyHydrationScoreToday, scoreJson);
  }

  /// Get today's hydration score
  String? getHydrationScoreToday() {
    return _prefs.getString(_keyHydrationScoreToday);
  }

  /// Save previous day's hydration score for history
  Future<bool> saveLastHydrationScore(String scoreJson) async {
    return await _prefs.setString(_keyLastHydrationScore, scoreJson);
  }

  /// Get previous day's hydration score
  String? getLastHydrationScore() {
    return _prefs.getString(_keyLastHydrationScore);
  }

  /// Clear today's hydration score
  Future<bool> clearHydrationScoreToday() async {
    return await _prefs.remove(_keyHydrationScoreToday);
  }

  // ============ DAILY RESET ============
  /// Save the last reset date
  Future<bool> saveLastResetDate(String dateString) async {
    return await _prefs.setString(_keyLastResetDate, dateString);
  }

  /// Get the last reset date
  String? getLastResetDate() {
    return _prefs.getString(_keyLastResetDate);
  }

  /// Get history log key for a specific date
  static String _getHistoryLogKey(DateTime date) {
    final dateStr = '${date.year}-${date.month}-${date.day}';
    return 'hydration_logs_$dateStr';
  }

  // ============ REMINDERS ============
  /// Save whether reminders are paused
  Future<bool> setReminderPaused(bool isPaused) async {
    return await _prefs.setBool(_keyReminderPaused, isPaused);
  }

  /// Check if reminders are paused
  bool getIsReminderPaused() {
    return _prefs.getBool(_keyReminderPaused) ?? false;
  }

  /// Save reminder resume time
  Future<bool> saveReminderResumeTime(String isoDateTime) async {
    return await _prefs.setString(_keyReminderResumeTime, isoDateTime);
  }

  /// Get reminder resume time
  String? getReminderResumeTime() {
    return _prefs.getString(_keyReminderResumeTime);
  }

  /// Clear reminder resume time
  Future<bool> clearReminderResumeTime() async {
    return await _prefs.remove(_keyReminderResumeTime);
  }

  /// Save recent notification IDs
  Future<bool> saveRecentNotifications(List<String> notificationIds) async {
    return await _prefs.setStringList(_keyRecentNotifications, notificationIds);
  }

  /// Get recent notification IDs
  List<String> getRecentNotifications() {
    return _prefs.getStringList(_keyRecentNotifications) ?? [];
  }

  // ============ ACHIEVEMENTS ============
  /// Save achievements data
  Future<bool> saveAchievements(String achievementsJson) async {
    return await _prefs.setString(_keyAchievements, achievementsJson);
  }

  /// Get achievements data
  String? getAchievements() {
    return _prefs.getString(_keyAchievements);
  }

  // ============ HYDRATION XP ============
  /// Save XP earned from hydration today
  Future<bool> saveHydrationXpToday(int xp) async {
    return await _prefs.setInt(_keyHydrationXpToday, xp);
  }

  /// Get XP earned from hydration today
  int getHydrationXpToday() {
    return _prefs.getInt(_keyHydrationXpToday) ?? 0;
  }

  /// Add to hydration XP earned today
  Future<bool> addHydrationXpToday(int xpToAdd) async {
    final current = getHydrationXpToday();
    return await saveHydrationXpToday(current + xpToAdd);
  }

  /// Save total XP earned from hydration (lifetime)
  Future<bool> saveHydrationTotalXp(int xp) async {
    return await _prefs.setInt(_keyHydrationTotalXp, xp);
  }

  /// Get total XP earned from hydration (lifetime)
  int getHydrationTotalXp() {
    return _prefs.getInt(_keyHydrationTotalXp) ?? 0;
  }

  /// Add to total hydration XP (lifetime)
  Future<bool> addHydrationTotalXp(int xpToAdd) async {
    final current = getHydrationTotalXp();
    return await saveHydrationTotalXp(current + xpToAdd);
  }

  /// Reset daily hydration XP
  Future<bool> resetHydrationXpToday() async {
    return await _prefs.setInt(_keyHydrationXpToday, 0);
  }

  // ============ APP METADATA ============
  /// Save app start date (for first-time setup)
  Future<bool> saveAppStartDate(String isoDateTime) async {
    return await _prefs.setString(_keyAppStartDate, isoDateTime);
  }

  /// Get app start date
  String? getAppStartDate() {
    return _prefs.getString(_keyAppStartDate);
  }

  // ============ BULK OPERATIONS ============
  /// Get all storage keys (useful for debugging and cleanup)
  Set<String> getAllKeys() {
    return _prefs.getKeys();
  }

  /// Remove a specific key from storage
  Future<bool> removeKey(String key) async {
    return await _prefs.remove(key);
  }

  /// Clear all storage (use with caution!)
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  /// Remove all history logs and reset data
  Future<void> clearAllHistoryLogs() async {
    final keys = getAllKeys();
    for (final key in keys) {
      if (key.startsWith('hydration_logs_') && key != _keyHydrationLogsToday) {
        await removeKey(key);
      }
    }
  }

  /// Remove old history logs (older than N days)
  Future<void> removeOldHistoryLogs(int daysToKeep) async {
    final keys = getAllKeys();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    for (final key in keys) {
      if (key.startsWith('hydration_logs_')) {
        try {
          final dateStr = key.replaceAll('hydration_logs_', '');
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            final logDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );

            if (logDate.isBefore(cutoffDate)) {
              await removeKey(key);
            }
          }
        } catch (e) {
          print('Error parsing storage key: $key');
        }
      }
    }
  }

  // ============ DEBUGGING ============
  /// Print all stored data (useful for debugging)
  void debugPrintAll() {
    print('=== StorageService Debug Info ===');
    final keys = getAllKeys();
    for (final key in keys) {
      final value = _prefs.get(key);
      print('$key: $value');
    }
    print('=================================');
  }

  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    return {
      'totalKeys': getAllKeys().length,
      'questKeys': getAllKeys().where((k) => k.startsWith('quests_')).length,
      'hydrationLogKeys': getAllKeys().where((k) => k.startsWith('hydration_logs_')).length,
      'achievementData': getAchievements() != null,
      'hydrationGoal': getHydrationGoal() != null,
    };
  }
}
