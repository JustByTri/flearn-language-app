class Program {
  final String programId;
  final String name;
  final String description;

  Program({
    required this.programId,
    required this.name,
    required this.description,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      programId: json['programId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}