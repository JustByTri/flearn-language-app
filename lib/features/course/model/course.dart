
class Course {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int price;
  final int discountPrice;
  final String courseType;
  final String teacherName;
  final String language;
  final String courseLevel;
  final String courseSkill;
  final int numLessons;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
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
      id: json['courseID'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] as num).toInt(),
      discountPrice: (json['discountPrice'] as num).toInt(),
      courseType: json['courseType'],
      teacherName: json['teacherInfo']['fullName'],
      language: json['languageInfo']['name'],
      courseLevel: json['courseLevel'],
      courseSkill: json['courseSkill'],
      numLessons: json['numLessons'],
    );
  }
}
