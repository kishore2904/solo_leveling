class ReminderSchedule {
  final String id;
  final List<String> scheduledTimes; // HH:MM format
  DateTime? lastSentTime;
  int ignoreCount; // Consecutive ignores
  bool isPaused;
  DateTime? pauseUntil;
  final DateTime createdAt;
  DateTime updatedAt;

  ReminderSchedule({
    required this.id,
    required this.scheduledTimes,
    this.lastSentTime,
    this.ignoreCount = 0,
    this.isPaused = false,
    this.pauseUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if reminders are currently paused
  bool isCurrentlyPaused() {
    if (!isPaused) return false;
    if (pauseUntil == null) return true;
    return DateTime.now().isBefore(pauseUntil!);
  }

  /// Pause reminders for a specific duration
  void pauseReminders(Duration duration) {
    isPaused = true;
    pauseUntil = DateTime.now().add(duration);
    updatedAt = DateTime.now();
  }

  /// Resume reminders
  void resumeReminders() {
    isPaused = false;
    pauseUntil = null;
    updatedAt = DateTime.now();
  }

  /// Auto-resume if pause duration has expired
  void checkAndAutoResume() {
    if (isPaused && pauseUntil != null && DateTime.now().isAfter(pauseUntil!)) {
      resumeReminders();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduledTimes': scheduledTimes,
      'lastSentTime': lastSentTime?.toIso8601String(),
      'ignoreCount': ignoreCount,
      'isPaused': isPaused,
      'pauseUntil': pauseUntil?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReminderSchedule.fromJson(Map<String, dynamic> json) {
    return ReminderSchedule(
      id: json['id'],
      scheduledTimes: List<String>.from(json['scheduledTimes']),
      lastSentTime:
          json['lastSentTime'] != null ? DateTime.parse(json['lastSentTime']) : null,
      ignoreCount: json['ignoreCount'] ?? 0,
      isPaused: json['isPaused'] ?? false,
      pauseUntil: json['pauseUntil'] != null ? DateTime.parse(json['pauseUntil']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  ReminderSchedule copyWith({
    String? id,
    List<String>? scheduledTimes,
    DateTime? lastSentTime,
    int? ignoreCount,
    bool? isPaused,
    DateTime? pauseUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderSchedule(
      id: id ?? this.id,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      lastSentTime: lastSentTime ?? this.lastSentTime,
      ignoreCount: ignoreCount ?? this.ignoreCount,
      isPaused: isPaused ?? this.isPaused,
      pauseUntil: pauseUntil ?? this.pauseUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
