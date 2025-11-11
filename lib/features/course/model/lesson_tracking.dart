class LessonProgress {
  final String enrollmentId;
  final String unitProgressId;
  final String lessonProgressId;
  final double lessonProgressPercent;
  final double unitProgressPercent;
  final double enrollmentProgressPercent;
  final String lessonStatus;
  final String unitStatus;
  final int totalTimeSpentMinutes;
  final String lastAccessedAt;

  LessonProgress({
    required this.enrollmentId,
    required this.unitProgressId,
    required this.lessonProgressId,
    required this.lessonProgressPercent,
    required this.unitProgressPercent,
    required this.enrollmentProgressPercent,
    required this.lessonStatus,
    required this.unitStatus,
    required this.totalTimeSpentMinutes,
    required this.lastAccessedAt,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      enrollmentId: json['enrollmentId'] ?? '',
      unitProgressId: json['unitProgressId'] ?? '',
      lessonProgressId: json['lessonProgressId'] ?? '',
      lessonProgressPercent: (json['lessonProgressPercent'] ?? 0).toDouble(),
      unitProgressPercent: (json['unitProgressPercent'] ?? 0).toDouble(),
      enrollmentProgressPercent: (json['enrollmentProgressPercent'] ?? 0).toDouble(),
      lessonStatus: json['lessonStatus'] ?? '',
      unitStatus: json['unitStatus'] ?? '',
      totalTimeSpentMinutes: json['totalTimeSpentMinutes'] ?? 0,
      lastAccessedAt: json['lastAccessedAt'] ?? '',
    );
  }
}