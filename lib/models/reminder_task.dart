class ReminderTask {
  final String id;
  final String title;
  final String description;
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime scheduledTime;
  final String category; // 'Work', 'Personal', 'Health', 'Other'
  final String icon; // emoji or icon name
  bool isCompleted;
  DateTime? completedAt;
  bool reminderSent;
  final String? recurrence; // 'none', 'daily', 'weekly', 'monthly'
  final String? parentReminderId; // For recurring instances, links to parent
  int completionCount; // Track how many times this has been completed

  ReminderTask({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.scheduledTime,
    required this.category,
    required this.icon,
    this.isCompleted = false,
    this.completedAt,
    this.reminderSent = false,
    this.recurrence = 'none',
    this.parentReminderId,
    this.completionCount = 0,
  });

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'scheduledTime': scheduledTime.toIso8601String(),
      'category': category,
      'icon': icon,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'reminderSent': reminderSent,
      'recurrence': recurrence ?? 'none',
      'parentReminderId': parentReminderId,
      'completionCount': completionCount,
    };
  }

  // Create from JSON
  factory ReminderTask.fromJson(Map<String, dynamic> json) {
    return ReminderTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      category: json['category'],
      icon: json['icon'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      reminderSent: json['reminderSent'] ?? false,
      recurrence: json['recurrence'] ?? 'none',
      parentReminderId: json['parentReminderId'],
      completionCount: json['completionCount'] ?? 0,
    );
  }

  /// Get time remaining until reminder
  Duration getTimeRemaining() {
    return scheduledTime.difference(DateTime.now());
  }

  /// Check if reminder is overdue
  bool isOverdue() {
    return DateTime.now().isAfter(scheduledTime) && !isCompleted;
  }

  /// Get display text for scheduled time
  String getScheduledTimeDisplay() {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue by ${(-difference.inHours)} hours';
    }
    
    if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes away';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} away';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} away';
    }
  }

  /// Get priority color
  String getPriorityColor() {
    switch (priority) {
      case 'High':
        return '#FF6B6B';
      case 'Medium':
        return '#FFB74D';
      case 'Low':
        return '#4ECDC4';
      default:
        return '#00D9FF';
    }
  }
}
