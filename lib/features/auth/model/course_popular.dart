class CoursePopular {
  final String courseId;
  final String title;
  final String teacherName;
  final int price;
  final double averageRating;
  final int reviewCount;
  final int learnerCount;
  final String imageUrl;
  final String programName;
  final String proficiencyCode;

  CoursePopular({
    required this.courseId,
    required this.title,
    required this.teacherName,
    required this.price,
    required this.averageRating,
    required this.reviewCount,
    required this.learnerCount,
    required this.imageUrl,
    required this.programName,
    required this.proficiencyCode,
  });

  factory CoursePopular.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return CoursePopular(
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      teacherName: json['teacherName'] ?? '',
      price: parseInt(json['price']),
      averageRating: parseDouble(json['averageRating']),
      reviewCount: parseInt(json['reviewCount']),
      learnerCount: parseInt(json['learnerCount']),
      imageUrl: json['imageUrl'] ?? '',
      programName: json['programName'] ?? '',
      proficiencyCode: json['proficiencyCode'] ?? '',
    );
  }
}