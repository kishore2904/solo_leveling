import 'package:flutter/material.dart';

class HydrationGoal {
  final String id;
  final double dailyGoalMl; // 2000 ml
  final double userWeight; // kg
  final String activityLevel; // 'Sedentary', 'Light', 'Moderate', 'High', 'VeryHigh'
  final TimeOfDay wakeUpTime; // 7:00 AM
  final TimeOfDay sleepTime; // 11:00 PM
  final int reminderIntervalMinutes; // 120
  final bool autoCalculateGoal; // true = use smart engine
  final DateTime createdAt;
  DateTime updatedAt;

  HydrationGoal({
    required this.id,
    required this.dailyGoalMl,
    required this.userWeight,
    required this.activityLevel,
    required this.wakeUpTime,
    required this.sleepTime,
    required this.reminderIntervalMinutes,
    required this.autoCalculateGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate recommended water intake based on weight, activity, and temperature
  double getRecommendedIntake(double tempCelsius) {
    // Base: Weight × 35 ml
    double baseIntake = userWeight * 35;

    // Activity adjustment
    double activityAdjustment = switch (activityLevel) {
      'Sedentary' => 0,
      'Light' => baseIntake * 0.10, // +10%
      'Moderate' => baseIntake * 0.20, // +20%
      'High' => baseIntake * 0.30, // +30%
      'VeryHigh' => baseIntake * 0.40, // +40%
      _ => 0,
    };

    // Temperature adjustment
    double tempAdjustment = switch (tempCelsius) {
      < 15 => baseIntake * -0.10, // -10%
      >= 15 && < 20 => 0,
      >= 20 && < 25 => baseIntake * 0.10, // +10%
      >= 25 && < 35 => baseIntake * 0.20, // +20%
      >= 35 => baseIntake * 0.30, // +30%
      _ => 0,
    };

    return baseIntake + activityAdjustment + tempAdjustment;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dailyGoalMl': dailyGoalMl,
      'userWeight': userWeight,
      'activityLevel': activityLevel,
      'wakeUpTime': '${wakeUpTime.hour}:${wakeUpTime.minute.toString().padLeft(2, '0')}',
      'sleepTime': '${sleepTime.hour}:${sleepTime.minute.toString().padLeft(2, '0')}',
      'reminderIntervalMinutes': reminderIntervalMinutes,
      'autoCalculateGoal': autoCalculateGoal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HydrationGoal.fromJson(Map<String, dynamic> json) {
    final wakeTimeParts = (json['wakeUpTime'] as String).split(':');
    final sleepTimeParts = (json['sleepTime'] as String).split(':');

    return HydrationGoal(
      id: json['id'],
      dailyGoalMl: (json['dailyGoalMl'] as num).toDouble(),
      userWeight: (json['userWeight'] as num).toDouble(),
      activityLevel: json['activityLevel'],
      wakeUpTime: TimeOfDay(
        hour: int.parse(wakeTimeParts[0]),
        minute: int.parse(wakeTimeParts[1]),
      ),
      sleepTime: TimeOfDay(
        hour: int.parse(sleepTimeParts[0]),
        minute: int.parse(sleepTimeParts[1]),
      ),
      reminderIntervalMinutes: json['reminderIntervalMinutes'],
      autoCalculateGoal: json['autoCalculateGoal'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  HydrationGoal copyWith({
    String? id,
    double? dailyGoalMl,
    double? userWeight,
    String? activityLevel,
    TimeOfDay? wakeUpTime,
    TimeOfDay? sleepTime,
    int? reminderIntervalMinutes,
    bool? autoCalculateGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HydrationGoal(
      id: id ?? this.id,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      userWeight: userWeight ?? this.userWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      sleepTime: sleepTime ?? this.sleepTime,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      autoCalculateGoal: autoCalculateGoal ?? this.autoCalculateGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
