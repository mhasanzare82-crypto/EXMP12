class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.activityId,
    required this.count,
    required this.createdAt,
    this.reason,
  });

  final String id;
  final String activityId;
  final int count;
  final DateTime createdAt;
  final String? reason;

  Map<String, dynamic> toJson() => {
    'id': id,
    'activityId': activityId,
    'count': count,
    'createdAt': createdAt.toIso8601String(),
    'reason': reason,
  };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
    id: json['id'] as String,
    activityId: json['activityId'] as String,
    count: json['count'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    reason: json['reason'] as String?,
  );
}
