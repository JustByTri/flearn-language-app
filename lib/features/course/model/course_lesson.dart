class Lesson {
  final String lessonID;
  final String title;
  final String content;
  final int position;
  final String description;
  final int totalExercises;
  final String videoUrl;
  final String documentUrl;
  final String courseUnitID;
  final String unitTitle;
  final String courseID;
  final String courseTitle;
  final String createdAt;
  final String updatedAt;

  Lesson({
    required this.lessonID,
    required this.title,
    required this.content,
    required this.position,
    required this.description,
    required this.totalExercises,
    required this.videoUrl,
    required this.documentUrl,
    required this.courseUnitID,
    required this.unitTitle,
    required this.courseID,
    required this.courseTitle,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      lessonID: json['lessonID'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      position: json['position'] ?? 0,
      description: json['description'] ?? '',
      totalExercises: json['totalExercises'] ?? 0,
      videoUrl: json['videoUrl'] ?? '',
      documentUrl: json['documentUrl'] ?? '',
      courseUnitID: json['courseUnitID'] ?? '',
      unitTitle: json['unitTitle'] ?? '',
      courseID: json['courseID'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}