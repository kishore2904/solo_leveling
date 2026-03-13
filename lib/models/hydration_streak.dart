class HydrationStreak {
  final String id;
  int currentStreak; // Days
  int longestStreak; // Best ever
  DateTime lastCompletionDate; // Last day goal was met
  List<DateTime> streakDates; // Backup record of dates

  HydrationStreak({
    required this.id,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletionDate,
    required this.streakDates,
  });

  /// Check if streak should continue or reset based on current date
  void updateStreak(bool goalMetToday) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (goalMetToday) {
      if (lastCompletionDate.isAfter(yesterday) ||
          DateTime(lastCompletionDate.year, lastCompletionDate.month, lastCompletionDate.day)
              .isAtSameMomentAs(yesterday)) {
        // Streak continues
        currentStreak++;
      } else {
        // Start new streak
        currentStreak = 1;
      }
      streakDates.add(today);
      lastCompletionDate = today;

      // Update longest streak
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    } else {
      // Reset streak if goal not met today
      if (!DateTime(lastCompletionDate.year, lastCompletionDate.month, lastCompletionDate.day)
          .isAtSameMomentAs(today)) {
        currentStreak = 0;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletionDate': lastCompletionDate.toIso8601String(),
      'streakDates': streakDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory HydrationStreak.fromJson(Map<String, dynamic> json) {
    return HydrationStreak(
      id: json['id'],
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastCompletionDate: DateTime.parse(json['lastCompletionDate']),
      streakDates: (json['streakDates'] as List)
          .map((d) => DateTime.parse(d as String))
          .toList(),
    );
  }

  HydrationStreak copyWith({
    String? id,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletionDate,
    List<DateTime>? streakDates,
  }) {
    return HydrationStreak(
      id: id ?? this.id,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      streakDates: streakDates ?? this.streakDates,
    );
  }
}
