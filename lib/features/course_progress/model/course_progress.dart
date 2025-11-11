class CourseProgress {
  final String enrollmentId;
  final String courseId;
  final String courseTitle;
  final String courseImage;
  final String language;
  final String level;
  final String teacherName;
  final String teacherAvatar;
  final int progressPercent;
  final String status;
  final String lastAccessedAt;
  final String enrolledAt;
  final int totalLessons;
  final int completedLessons;
  final int totalUnits;
  final int completedUnits;
  final String currentUnit;
  final String currentLesson;
  final String nextLesson;
  final bool isExpired;
  final String accessUntil;

  CourseProgress({
    required this.enrollmentId,
    required this.courseId,
    required this.courseTitle,
    required this.courseImage,
    required this.language,
    required this.level,
    required this.teacherName,
    required this.teacherAvatar,
    required this.progressPercent,
    required this.status,
    required this.lastAccessedAt,
    required this.enrolledAt,
    required this.totalLessons,
    required this.completedLessons,
    required this.totalUnits,
    required this.completedUnits,
    required this.currentUnit,
    required this.currentLesson,
    required this.nextLesson,
    required this.isExpired,
    required this.accessUntil,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      enrollmentId: json['enrollmentId'] ?? '',
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      courseImage: json['courseImage'] ?? '',
      language: json['language'] ?? '',
      level: json['level'] ?? '',
      teacherName: json['teacherName'] ?? '',
      teacherAvatar: json['teacherAvatar'] ?? '',
      progressPercent: json['progressPercent'] ?? 0,
      status: json['status'] ?? '',
      lastAccessedAt: json['lastAccessedAt'] ?? '',
      enrolledAt: json['enrolledAt'] ?? '',
      totalLessons: json['totalLessons'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      totalUnits: json['totalUnits'] ?? 0,
      completedUnits: json['completedUnits'] ?? 0,
      currentUnit: json['currentUnit'] ?? '',
      currentLesson: json['currentLesson'] ?? '',
      nextLesson: json['nextLesson'] ?? '',
      isExpired: json['isExpired'] ?? false,
      accessUntil: json['accessUntil'] ?? '',
    );
  }
}