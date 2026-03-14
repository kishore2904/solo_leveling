/// Service to manage player level progression with defined XP thresholds
class LevelProgressionService {
  static final LevelProgressionService _instance =
      LevelProgressionService._internal();

  factory LevelProgressionService() {
    return _instance;
  }

  LevelProgressionService._internal();

  /// Define XP requirements for each level
  /// Key: Level number, Value: XP required to reach that level
  static const Map<int, int> levelXpRequirements = {
    1: 250,
    2: 400,
    3: 600,
    4: 850,
    5: 1150,
    6: 1500,
    7: 1900,
    8: 2350,
    9: 2850,
    10: 3400,
    11: 4000,
    12: 4650,
    13: 5350,
    14: 6100,
    15: 6900,
    16: 7750,
    17: 8650,
    18: 9600,
    19: 10600,
    20: 11650,
    // Scaling: level 20+ uses formula: 10000 + (level * 1200)
  };

  /// Get XP required for a specific level
  int getXpRequiredForLevel(int level) {
    if (levelXpRequirements.containsKey(level)) {
      return levelXpRequirements[level]!;
    }
    // For levels beyond 20, use scaling formula
    if (level > 20) {
      return 10000 + (level * 1200);
    }
    return 11650; // Default to level 20 requirement if not found
  }

  /// Calculate level and current XP from total XP earned
  /// Returns: {'level': int, 'currentXp': int, 'requiredXp': int, 'nextLevelXp': int}
  Map<String, int> calculateLevelFromTotalXp(int totalXpEarned) {
    int currentLevel = 1;
    int xpUsed = 0;

    // Find current level by checking cumulative XP
    while (xpUsed + getXpRequiredForLevel(currentLevel) <= totalXpEarned) {
      xpUsed += getXpRequiredForLevel(currentLevel);
      currentLevel += 1;
    }

    final currentLevelXp = totalXpEarned - xpUsed;
    final requiredXpForNextLevel = getXpRequiredForLevel(currentLevel);

    return {
      'level': currentLevel,
      'currentXp': currentLevelXp,
      'requiredXp': requiredXpForNextLevel,
      'nextLevelXp': currentLevel + 1,
    };
  }

  /// Check if player leveled up and return new level info
  Map<String, dynamic> checkLevelUp({
    required int previousTotalXp,
    required int newTotalXp,
  }) {
    final previousLevelInfo = calculateLevelFromTotalXp(previousTotalXp);
    final newLevelInfo = calculateLevelFromTotalXp(newTotalXp);

    final previousLevel = previousLevelInfo['level']!;
    final newLevel = newLevelInfo['level']!;

    return {
      'leveledUp': newLevel > previousLevel,
      'previousLevel': previousLevel,
      'newLevel': newLevel,
      'levelUpCount': newLevel - previousLevel,
      'currentLevel': newLevel,
      'currentXp': newLevelInfo['currentXp']!,
      'requiredXp': newLevelInfo['requiredXp']!,
      'totalXp': newTotalXp,
    };
  }

  /// Get total XP needed to reach a specific level
  int getTotalXpForLevel(int targetLevel) {
    int totalXp = 0;
    for (int i = 1; i < targetLevel; i++) {
      totalXp += getXpRequiredForLevel(i);
    }
    return totalXp;
  }

  /// Get level progress as percentage (0-100)
  int getLevelProgressPercentage({
    required int currentXp,
    required int requiredXp,
  }) {
    if (requiredXp == 0) return 0;
    return ((currentXp / requiredXp) * 100).clamp(0, 100).toInt();
  }

  /// Get user-friendly XP display (e.g., "250/400 XP")
  String getXpDisplay({
    required int currentXp,
    required int requiredXp,
  }) {
    return '$currentXp/$requiredXp XP';
  }

  /// Get all level requirements as a list (useful for UI)
  List<Map<String, int>> getAllLevelRequirements({int maxLevels = 50}) {
    final requirements = <Map<String, int>>[];
    for (int i = 1; i <= maxLevels; i++) {
      requirements.add({
        'level': i,
        'xpRequired': getXpRequiredForLevel(i),
        'totalXpToReach': getTotalXpForLevel(i),
      });
    }
    return requirements;
  }
}
