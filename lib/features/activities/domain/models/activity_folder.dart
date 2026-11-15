class ActivityFolder {
  const ActivityFolder({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory ActivityFolder.fromJson(Map<String, dynamic> json) => ActivityFolder(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
