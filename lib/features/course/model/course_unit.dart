class CourseUnit {
  final String courseUnitID;
  final String title;
  final String description;
  final int position;
  final String courseID;
  final String courseTitle;
  final int totalLessons;
  final bool isPreview;
  final String createdAt;
  final String updatedAt;

  CourseUnit({
    required this.courseUnitID,
    required this.title,
    required this.description,
    required this.position,
    required this.courseID,
    required this.courseTitle,
    required this.totalLessons,
    required this.isPreview,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseUnit.fromJson(Map<String, dynamic> json) {
    return CourseUnit(
      courseUnitID: json['courseUnitID'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      position: json['position'] ?? 0,
      courseID: json['courseID'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      totalLessons: json['totalLessons'] ?? 0,
      isPreview: json['isPreview'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}