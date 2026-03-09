class DailyQuest {
  final String id;
  final String title;
  final String description;
  final String category; // 'Health', 'Learning', 'Wellness'
  final String icon; // emoji or icon name
  final String color; // hex color code
  final int xpReward;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final String timeWindow; // e.g., "6:00 AM - 10:00 AM"
  bool isCompleted;
  DateTime? completedAt;
  String? notes;

  DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.xpReward,
    required this.difficulty,
    required this.timeWindow,
    this.isCompleted = false,
    this.completedAt,
    this.notes,
  });

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'icon': icon,
      'color': color,
      'xpReward': xpReward,
      'difficulty': difficulty,
      'timeWindow': timeWindow,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  // Create from JSON
  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      icon: json['icon'],
      color: json['color'],
      xpReward: json['xpReward'],
      difficulty: json['difficulty'],
      timeWindow: json['timeWindow'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      notes: json['notes'],
    );
  }
}
