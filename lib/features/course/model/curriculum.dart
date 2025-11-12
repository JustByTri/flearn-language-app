class Curriculum {
  final String enrollmentId;
  final String courseTitle;
  final List<CurriculumUnit> units;

  Curriculum({
    required this.enrollmentId,
    required this.courseTitle,
    required this.units,
  });

  factory Curriculum.fromJson(Map<String, dynamic> json) {
    return Curriculum(
      enrollmentId: json['enrollmentId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      units: (json['units'] as List<dynamic>?)
          ?.map((e) => CurriculumUnit.fromJson(e))
          .toList() ?? [],
    );
  }
}

class CurriculumUnit {
  final String unitId;
  final String title;
  final int order;
  final double progressPercent; // Đổi từ int sang double
  final String status;
  final String? completedAt;
  final List<CurriculumLesson> lessons;

  CurriculumUnit({
    required this.unitId,
    required this.title,
    required this.order,
    required this.progressPercent,
    required this.status,
    this.completedAt,
    required this.lessons,
  });

  factory CurriculumUnit.fromJson(Map<String, dynamic> json) {
    return CurriculumUnit(
      unitId: json['unitId'] ?? '',
      title: json['title'] ?? '',
      order: json['order'] ?? 0,
      progressPercent: (json['progressPercent'] ?? 0).toDouble(), // Convert to double
      status: json['status'] ?? '',
      completedAt: json['completedAt'],
      lessons: (json['lessons'] as List<dynamic>?)
          ?.map((e) => CurriculumLesson.fromJson(e))
          .toList() ?? [],
    );
  }
}

class CurriculumLesson {
  final String lessonId;
  final String title;
  final int order;
  final double progressPercent; // Đổi từ int sang double
  final String status;
  final bool hasContent;
  final bool hasVideo;
  final bool hasDocument;
  final bool hasExercise;

  CurriculumLesson({
    required this.lessonId,
    required this.title,
    required this.order,
    required this.progressPercent,
    required this.status,
    required this.hasContent,
    required this.hasVideo,
    required this.hasDocument,
    required this.hasExercise,
  });

  factory CurriculumLesson.fromJson(Map<String, dynamic> json) {
    return CurriculumLesson(
      lessonId: json['lessonId'] ?? '',
      title: json['title'] ?? '',
      order: json['order'] ?? 0,
      progressPercent: (json['progressPercent'] ?? 0).toDouble(), // Convert to double
      status: json['status'] ?? '',
      hasContent: json['hasContent'] ?? false,
      hasVideo: json['hasVideo'] ?? false,
      hasDocument: json['hasDocument'] ?? false,
      hasExercise: json['hasExercise'] ?? false,
    );
  }
}