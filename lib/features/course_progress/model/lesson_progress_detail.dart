class LessonProgressDetail {
  final String lessonProgressId;
  final String lessonId;
  final String lessonTitle;
  final String description;
  final double progressPercent;
  final String status;
  final String? startedAt;
  final String? completedAt;
  final String? lastUpdated;
  final ActivityStatus activityStatus;
  final int totalExercises;
  final int completedExercises;
  final int passedExercises;
  final String unitId;
  final String unitTitle;
  final String courseId;
  final String courseTitle;

  LessonProgressDetail({
    required this.lessonProgressId,
    required this.lessonId,
    required this.lessonTitle,
    required this.description,
    required this.progressPercent,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.lastUpdated,
    required this.activityStatus,
    required this.totalExercises,
    required this.completedExercises,
    required this.passedExercises,
    required this.unitId,
    required this.unitTitle,
    required this.courseId,
    required this.courseTitle,
  });

  factory LessonProgressDetail.fromJson(Map<String, dynamic> json) {
    return LessonProgressDetail(
      lessonProgressId: json['lessonProgressId'] ?? '',
      lessonId: json['lessonId'] ?? '',
      lessonTitle: json['lessonTitle'] ?? '',
      description: json['description'] ?? '',
      progressPercent: (json['progressPercent'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      startedAt: json['startedAt'],
      completedAt: json['completedAt'],
      lastUpdated: json['lastUpdated'],
      activityStatus: ActivityStatus.fromJson(json['activityStatus'] ?? {}),
      totalExercises: json['totalExercises'] ?? 0,
      completedExercises: json['completedExercises'] ?? 0,
      passedExercises: json['passedExercises'] ?? 0,
      unitId: json['unitId'] ?? '',
      unitTitle: json['unitTitle'] ?? '',
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
    );
  }
}

class ActivityStatus {
  final bool isContentViewed;
  final bool isVideoWatched;
  final bool isDocumentRead;
  final bool isPracticeCompleted;
  final ResourceStatus content;
  final ResourceStatus video;
  final ResourceStatus document;

  ActivityStatus({
    required this.isContentViewed,
    required this.isVideoWatched,
    required this.isDocumentRead,
    required this.isPracticeCompleted,
    required this.content,
    required this.video,
    required this.document,
  });

  factory ActivityStatus.fromJson(Map<String, dynamic> json) {
    return ActivityStatus(
      isContentViewed: json['isContentViewed'] ?? false,
      isVideoWatched: json['isVideoWatched'] ?? false,
      isDocumentRead: json['isDocumentRead'] ?? false,
      isPracticeCompleted: json['isPracticeCompleted'] ?? false,
      content: ResourceStatus.fromJson(json['content'] ?? {}),
      video: ResourceStatus.fromJson(json['video'] ?? {}),
      document: ResourceStatus.fromJson(json['document'] ?? {}),
    );
  }
}

class ResourceStatus {
  final bool isAvailable;
  final bool isCompleted;
  final String? completedAt;
  final String? resourceUrl;
  final String? resourceTitle;

  ResourceStatus({
    required this.isAvailable,
    required this.isCompleted,
    this.completedAt,
    this.resourceUrl,
    this.resourceTitle,
  });

  factory ResourceStatus.fromJson(Map<String, dynamic> json) {
    return ResourceStatus(
      isAvailable: json['isAvailable'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'],
      resourceUrl: json['resourceUrl'],
      resourceTitle: json['resourceTitle'],
    );
  }
}