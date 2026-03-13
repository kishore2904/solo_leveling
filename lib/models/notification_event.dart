class NotificationEvent {
  final String id;
  final DateTime sentTime;
  final String action; // 'sent', 'completed', 'skipped', 'ignored'
  final DateTime? actionTime;
  final int? amountLogged; // ml logged if action is 'completed'
  final String? source; // 'notification', 'manual', etc.

  NotificationEvent({
    required this.id,
    required this.sentTime,
    required this.action,
    this.actionTime,
    this.amountLogged,
    this.source,
  });

  /// Get time difference between notification sent and action taken (in minutes)
  int? getResponseTimeMinutes() {
    if (actionTime == null) return null;
    return actionTime!.difference(sentTime).inMinutes;
  }

  /// Check if notification was ignored (sent but no action taken within reasonable time)
  bool isIgnored(int timeoutMinutes) {
    if (action != 'sent') return false;
    return DateTime.now().difference(sentTime).inMinutes > timeoutMinutes;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sentTime': sentTime.toIso8601String(),
      'action': action,
      'actionTime': actionTime?.toIso8601String(),
      'amountLogged': amountLogged,
      'source': source,
    };
  }

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      id: json['id'],
      sentTime: DateTime.parse(json['sentTime']),
      action: json['action'],
      actionTime: json['actionTime'] != null ? DateTime.parse(json['actionTime']) : null,
      amountLogged: json['amountLogged'],
      source: json['source'],
    );
  }

  NotificationEvent copyWith({
    String? id,
    DateTime? sentTime,
    String? action,
    DateTime? actionTime,
    int? amountLogged,
    String? source,
  }) {
    return NotificationEvent(
      id: id ?? this.id,
      sentTime: sentTime ?? this.sentTime,
      action: action ?? this.action,
      actionTime: actionTime ?? this.actionTime,
      amountLogged: amountLogged ?? this.amountLogged,
      source: source ?? this.source,
    );
  }
}
