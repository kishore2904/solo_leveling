class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category; // 'Streak', 'Quests', 'Fitness', 'Learning'
  bool isUnlocked;
  DateTime? unlockedAt;
  int progress; // Current progress (0-100)
  int requirement; // What's needed to unlock

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
    required this.requirement,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'progress': progress,
      'requirement': requirement,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      category: json['category'],
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
      progress: json['progress'] ?? 0,
      requirement: json['requirement'],
    );
  }
}
