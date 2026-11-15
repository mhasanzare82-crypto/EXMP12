class Activity {
  const Activity({required this.id, required this.name, this.folderId});

  final String id;
  final String name;
  final String? folderId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'folderId': folderId,
      };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'] as String,
        name: json['name'] as String,
        folderId: json['folderId'] as String?,
      );

  Activity copyWith({String? folderId, bool clearFolder = false}) => Activity(
        id: id,
        name: name,
        folderId: clearFolder ? null : (folderId ?? this.folderId),
      );
}
