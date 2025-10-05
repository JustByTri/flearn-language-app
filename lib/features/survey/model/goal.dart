class Goal {
  final int id;
  final String name;
  final String description;

  Goal({required this.id, required this.name, required this.description});

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}