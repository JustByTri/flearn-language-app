class Course {
  final String courseID;
  final String title;
  final String description;
  final String imageUrl;
  final String? publishedAt;
  final String? status;
  final int price;
  final int discountPrice;
  final String courseType;
  final String teacherName;
  final String language;
  final String courseLevel;
  final String courseSkill;
  final int numLessons;
  final List<String> topics;
  Course({
    required this.courseID,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.publishedAt,
    this.status,
    required this.price,
    required this.topics,
    required this.discountPrice,
    required this.courseType,
    required this.teacherName,
    required this.language,
    required this.courseLevel,
    required this.courseSkill,
    required this.numLessons,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseID: json['courseID'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      publishedAt: json['publishedAt'],
      status: json['status'],
      price: (json['price'] ?? 0) is num ? (json['price'] ?? 0).toInt() : 0,
      discountPrice: (json['discountPrice'] ?? 0) is num ? (json['discountPrice'] ?? 0).toInt() : 0,
      courseType: json['courseType'] ?? '',
      teacherName: json['teacherInfo']?['fullName'] ?? '',
      language: json['languageInfo']?['name'] ?? '',
      courseLevel: json['courseLevel'] ?? '',
      courseSkill: json['courseSkill'] ?? '',
      topics : (json['topics'] as List<dynamic>? ?? [])
          .map((e) => e['topicName']?.toString() ?? '')
          .toList(),
      numLessons: (json['numLessons'] ?? 0) is int ? json['numLessons'] : int.tryParse(json['numLessons']?.toString() ?? '0') ?? 0,
    );
  }
}
