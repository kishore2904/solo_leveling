class HydrationLog {
  final String id;
  final double amountMl; // 250 ml
  final DateTime timestamp; // Auto-recorded
  final String source; // 'manual', 'notification', 'quick_button'
  final String? notes;
  final DateTime dateLogged; // For daily grouping

  HydrationLog({
    required this.id,
    required this.amountMl,
    required this.timestamp,
    required this.source,
    this.notes,
    required this.dateLogged,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amountMl': amountMl,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'notes': notes,
      'dateLogged': dateLogged.toIso8601String(),
    };
  }

  factory HydrationLog.fromJson(Map<String, dynamic> json) {
    return HydrationLog(
      id: json['id'],
      amountMl: (json['amountMl'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      source: json['source'],
      notes: json['notes'],
      dateLogged: DateTime.parse(json['dateLogged']),
    );
  }

  HydrationLog copyWith({
    String? id,
    double? amountMl,
    DateTime? timestamp,
    String? source,
    String? notes,
    DateTime? dateLogged,
  }) {
    return HydrationLog(
      id: id ?? this.id,
      amountMl: amountMl ?? this.amountMl,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      dateLogged: dateLogged ?? this.dateLogged,
    );
  }
}
