class HydrationScore {
  final String id;
  int score; // 0-100
  double intakePercentage; // (consumed / goal) * 100
  int timelinessBonus; // +10 for consistent timing
  int responseBonus; // +5 for notification responsiveness
  int ignoreDeduction; // -5 per ignore (capped)
  final DateTime dateRecorded;

  HydrationScore({
    required this.id,
    required this.score,
    required this.intakePercentage,
    required this.timelinessBonus,
    required this.responseBonus,
    required this.ignoreDeduction,
    required this.dateRecorded,
  });

  /// Calculate daily hydration score based on intake and engagement
  static int calculateScore(
    double consumedMl,
    double dailyGoalMl,
    int onTimeLogsCount,
    int totalRemindersCount,
    int ignoreCount,
  ) {
    // Base score: (consumed / goal) × 100
    double intakePercentage = (consumedMl / dailyGoalMl) * 100;
    int baseScore = (intakePercentage.clamp(0, 100)).toInt();

    // Timelines bonus: +10 if user logs within ±30 min of planned reminders
    int timelinessBonus = (onTimeLogsCount > 0) ? 10 : 0;

    // Response bonus: +5 for notification responsiveness (low ignore rate)
    int responseBonus = 0;
    if (totalRemindersCount > 0) {
      double ignoreRate = ignoreCount / totalRemindersCount;
      if (ignoreRate < 0.1) {
        responseBonus = 5;
      }
    }

    // Ignore deduction: -5 per ignore after 3 ignores (capped at -15)
    int ignoreDeduction = 0;
    if (ignoreCount > 3) {
      ignoreDeduction = ((ignoreCount - 3) * -5).clamp(-15, 0);
    }

    // Final score (capped at 100)
    int finalScore = (baseScore + timelinessBonus + responseBonus + ignoreDeduction)
        .clamp(0, 100);

    return finalScore;
  }

  /// Get score rating (label)
  String getScoreRating() {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Great';
    if (score >= 50) return 'Good';
    if (score >= 25) return 'Fair';
    return 'Poor';
  }

  /// Get score color description
  String getScoreColorHint() {
    if (score >= 90) return 'green';
    if (score >= 75) return 'lightBlue';
    if (score >= 50) return 'orange';
    if (score >= 25) return 'deepOrange';
    return 'red';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'score': score,
      'intakePercentage': intakePercentage,
      'timelinessBonus': timelinessBonus,
      'responseBonus': responseBonus,
      'ignoreDeduction': ignoreDeduction,
      'dateRecorded': dateRecorded.toIso8601String(),
    };
  }

  factory HydrationScore.fromJson(Map<String, dynamic> json) {
    return HydrationScore(
      id: json['id'],
      score: json['score'],
      intakePercentage: (json['intakePercentage'] as num).toDouble(),
      timelinessBonus: json['timelinessBonus'],
      responseBonus: json['responseBonus'],
      ignoreDeduction: json['ignoreDeduction'],
      dateRecorded: DateTime.parse(json['dateRecorded']),
    );
  }

  HydrationScore copyWith({
    String? id,
    int? score,
    double? intakePercentage,
    int? timelinessBonus,
    int? responseBonus,
    int? ignoreDeduction,
    DateTime? dateRecorded,
  }) {
    return HydrationScore(
      id: id ?? this.id,
      score: score ?? this.score,
      intakePercentage: intakePercentage ?? this.intakePercentage,
      timelinessBonus: timelinessBonus ?? this.timelinessBonus,
      responseBonus: responseBonus ?? this.responseBonus,
      ignoreDeduction: ignoreDeduction ?? this.ignoreDeduction,
      dateRecorded: dateRecorded ?? this.dateRecorded,
    );
  }
}
