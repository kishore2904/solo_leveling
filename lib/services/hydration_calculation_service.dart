import 'package:solo_leveling/models/hydration_goal.dart';

class HydrationCalculationService {
  static final HydrationCalculationService _instance =
      HydrationCalculationService._internal();

  factory HydrationCalculationService() {
    return _instance;
  }

  HydrationCalculationService._internal();

  /// Calculate recommended daily water intake based on user factors
  /// Formula: (Weight in kg × 35 ml) + Activity Adjustment + Temperature Adjustment
  int calculateRecommendedIntake({
    required double weightKg,
    required String activityLevel,
    required double temperatureCelsius,
  }) {
    // Base calculation: Weight × 35 ml
    int baseIntake = (weightKg * 35).toInt();

    // Activity level adjustment
    double activityMultiplier = _getActivityMultiplier(activityLevel);
    int activityAdjustment = (baseIntake * (activityMultiplier - 1)).toInt();

    // Temperature adjustment
    double temperatureMultiplier = _getTemperatureMultiplier(temperatureCelsius);
    int temperatureAdjustment =
        (baseIntake * (temperatureMultiplier - 1)).toInt();

    // Final calculation
    int recommendedIntake = baseIntake + activityAdjustment + temperatureAdjustment;

    // Ensure minimum 1.5L and maximum 4L
    if (recommendedIntake < 1500) recommendedIntake = 1500;
    if (recommendedIntake > 4000) recommendedIntake = 4000;

    return recommendedIntake;
  }

  /// Get activity level multiplier
  double _getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.0; // No adjustment
      case 'light':
        return 1.1; // +10%
      case 'moderate':
        return 1.2; // +20%
      case 'high':
        return 1.3; // +30%
      case 'veryhigh':
        return 1.4; // +40%
      default:
        return 1.2; // Default to moderate
    }
  }

  /// Get temperature adjustment multiplier
  double _getTemperatureMultiplier(double tempCelsius) {
    // Optimal temperature range: 15-25°C
    if (tempCelsius < 0) {
      return 1.0; // No adjustment for very cold
    } else if (tempCelsius < 15) {
      return 1.05; // +5% for cold
    } else if (tempCelsius <= 25) {
      return 1.0; // No adjustment for optimal
    } else if (tempCelsius < 35) {
      return 1.15; // +15% for warm
    } else {
      return 1.30; // +30% for hot
    }
  }

  /// Calculate hydration level (0-100%)
  int calculateHydrationLevel({
    required int consumedMl,
    required int goalMl,
  }) {
    if (goalMl <= 0) return 0;
    int level = ((consumedMl / goalMl) * 100).toInt();
    return level > 100 ? 100 : level;
  }

  /// Get hydration level status
  String getHydrationStatus(int consumedMl, int goalMl) {
    final percentage = calculateHydrationLevel(
      consumedMl: consumedMl,
      goalMl: goalMl,
    );

    if (percentage == 0) {
      return 'Start Hydrating';
    } else if (percentage < 25) {
      return 'Just Started';
    } else if (percentage < 50) {
      return 'Good Progress';
    } else if (percentage < 75) {
      return 'Almost There';
    } else if (percentage < 100) {
      return 'Nearly Complete';
    } else if (percentage == 100) {
      return 'Goal Reached!';
    } else {
      return 'Exceeded Goal!';
    }
  }

  /// Get hydration-related color based on percentage
  Map<String, dynamic> getHydrationColor(int consumedMl, int goalMl) {
    final percentage = calculateHydrationLevel(
      consumedMl: consumedMl,
      goalMl: goalMl,
    );

    if (percentage == 0) {
      return {'color': 0xFF808080, 'emoji': '⚪'};
    } else if (percentage < 25) {
      return {'color': 0xFFE74C3C, 'emoji': '🔴'};
    } else if (percentage < 50) {
      return {'color': 0xFFF39C12, 'emoji': '🟠'};
    } else if (percentage < 75) {
      return {'color': 0xFFFFC107, 'emoji': '🟡'};
    } else if (percentage < 100) {
      return {'color': 0xFF00D9FF, 'emoji': '🔵'};
    } else {
      return {'color': 0xFF00FF7F, 'emoji': '🟢'};
    }
  }

  /// Calculate how much water user should drink per hour
  int calculateIntakePerHour({
    required int dailyGoalMl,
    required int wakeHourUtc,
    required int sleepHourUtc,
  }) {
    int awakeHours = _calculateAwakeHours(wakeHourUtc, sleepHourUtc);
    return (dailyGoalMl / awakeHours).toInt();
  }

  /// Calculate recommended intake for next session (adaptive)
  int calculateAdaptiveIntake({
    required int totalConsumedMl,
    required int dailyGoalMl,
    required int hoursRemaining,
    required int sessionsRemaining,
  }) {
    if (sessionsRemaining <= 0) return 0;

    int remainingGoal = dailyGoalMl - totalConsumedMl;
    if (remainingGoal <= 0) return 0;

    // Distribute remaining goal evenly across remaining sessions
    int adaptiveIntake = (remainingGoal / sessionsRemaining).toInt();

    // Ensure it's a reasonable amount (100-750ml per session)
    if (adaptiveIntake < 100) adaptiveIntake = 100;
    if (adaptiveIntake > 750) adaptiveIntake = 750;

    return adaptiveIntake;
  }

  /// Get encouragement message based on hydration progress
  String getEncouragementMessage({
    required int consumedMl,
    required int goalMl,
    required int currentStreak,
  }) {
    final percentage = calculateHydrationLevel(
      consumedMl: consumedMl,
      goalMl: goalMl,
    );

    if (currentStreak > 30) {
      return 'Amazing dedication! Keep that $currentStreak day streak alive! 🔥';
    } else if (percentage >= 100) {
      return 'Daily goal achieved! You\'re hydrated! 🎉';
    } else if (percentage >= 75) {
      return 'Almost there! Just a little more to reach your goal! 💪';
    } else if (percentage >= 50) {
      return 'Great progress! Keep it up! 👏';
    } else if (percentage >= 25) {
      return 'Getting started! You\'ve got this! 🌟';
    } else if (percentage > 0) {
      return 'Every sip counts! Start your hydration journey! 💧';
    } else {
      return 'Time to hydrate! Your body will thank you! 💙';
    }
  }

  int _calculateAwakeHours(int wakeHourUtc, int sleepHourUtc) {
    if (sleepHourUtc > wakeHourUtc) {
      return sleepHourUtc - wakeHourUtc;
    } else {
      return (24 - wakeHourUtc) + sleepHourUtc;
    }
  }

  /// Check if user is behind on hydration goal
  bool isBehindSchedule({
    required int consumedMl,
    required int goalMl,
    required int elapsedMinutes,
    required int totalMinutesAwake,
  }) {
    if (totalMinutesAwake <= 0) return false;

    double expectedConsumption =
        (consumedMl / elapsedMinutes) * totalMinutesAwake;
    return expectedConsumption < goalMl * 0.8; // Behind if < 80% of expected
  }

  /// Get hydration deficit info
  Map<String, dynamic> getHydrationDeficit({
    required int consumedMl,
    required int goalMl,
  }) {
    final deficit = goalMl - consumedMl;
    final percentage = (deficit / goalMl * 100).toInt();

    String message;
    if (deficit <= 0) {
      message = 'You\'ve exceeded your goal!';
    } else if (deficit < 250) {
      message = 'Almost there!';
    } else if (deficit < 500) {
      message = 'A couple more glasses to go!';
    } else {
      message = 'Keep drinking to reach your goal!';
    }

    return {
      'deficit': deficit,
      'percentage': percentage,
      'message': message,
    };
  }
}
