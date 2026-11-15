class Activity {
  const Activity({required this.id, required this.name});
  final String id;
  final String name;
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Activity.fromJson(Map<String, dynamic> json) => Activity(id: json['id'] as String, name: json['name'] as String);
}
