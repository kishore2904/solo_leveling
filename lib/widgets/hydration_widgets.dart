import 'package:flutter/material.dart';

class HydrationProgressWidget extends StatelessWidget {
  final double consumed;
  final double goal;
  final bool showLabel;

  const HydrationProgressWidget({
    super.key,
    required this.consumed,
    required this.goal,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = ((consumed / goal) * 100).clamp(0, 100).toInt();
    final progressColor = _getProgressColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Progress',
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Color(0xFF00D9FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        if (showLabel) const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: (percentage / 100).clamp(0, 1),
            backgroundColor: const Color(0xFF00D9FF).withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${consumed.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} ml',
              style: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Color _getProgressColor(int percentage) {
    if (percentage < 25) return const Color(0xFFFF6B6B);
    if (percentage < 50) return const Color(0xFFFFA500);
    if (percentage < 75) return const Color(0xFF64E7FF);
    return const Color(0xFF00D9FF);
  }
}

/// Hydration Mini Widget for Home Screen
class HydrationMiniWidget extends StatelessWidget {
  final double consumed;
  final double goal;
  final int streak;
  final VoidCallback onTap;

  const HydrationMiniWidget({
    super.key,
    required this.consumed,
    required this.goal,
    required this.streak,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = ((consumed / goal) * 100).clamp(0, 100).toInt();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121B3A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00D9FF).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💧 Hydration',
                    style: TextStyle(
                      color: Color(0xFFF5F5F5),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🔥 $streak days',
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: (percentage / 100).clamp(0, 1),
                  backgroundColor: const Color(0xFF00D9FF).withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00D9FF),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${consumed.toStringAsFixed(0)} ml / ${goal.toStringAsFixed(0)} ml',
                style: const TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick Log Action Buttons
class QuickLogActionButton extends StatelessWidget {
  final int amount;
  final String label;
  final String icon;
  final VoidCallback onTap;

  const QuickLogActionButton({
    super.key,
    required this.amount,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF00D9FF).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hydration Stats Display Card
class HydrationStatsCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String? unit;
  final Color? accentColor;

  const HydrationStatsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? const Color(0xFF00D9FF);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121B3A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 12,
                ),
              ),
              Text(icon, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Streak Display Badge
class StreakBadge extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakBadge({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9FF), Color(0xFF00F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔥 Current Streak',
                style: TextStyle(
                  color: Color(0xFF0A0E27),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$currentStreak days',
                style: const TextStyle(
                  color: Color(0xFF0A0E27),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '🏆 Best Ever',
                style: TextStyle(
                  color: Color(0xFF0A0E27),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$longestStreak days',
                style: const TextStyle(
                  color: Color(0xFF0A0E27),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
