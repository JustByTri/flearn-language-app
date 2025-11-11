class Exercise {
  final String exerciseID;
  final String title;
  final String prompt;
  final String hints;
  final String content;
  final String expectedAnswer;
  final List<String> mediaUrls;
  final List<String> mediaPublicIds;
  final int position;
  final String exerciseType;
  final String difficulty;
  final int maxScore;
  final int passScore;
  final String feedbackCorrect;
  final String feedbackIncorrect;
  final String courseID;
  final String courseTitle;
  final String unitID;
  final String unitTitle;
  final String lessonID;
  final String lessonTitle;
  final String createdAt;
  final String updatedAt;

  Exercise({
    required this.exerciseID,
    required this.title,
    required this.prompt,
    required this.hints,
    required this.content,
    required this.expectedAnswer,
    required this.mediaUrls,
    required this.mediaPublicIds,
    required this.position,
    required this.exerciseType,
    required this.difficulty,
    required this.maxScore,
    required this.passScore,
    required this.feedbackCorrect,
    required this.feedbackIncorrect,
    required this.courseID,
    required this.courseTitle,
    required this.unitID,
    required this.unitTitle,
    required this.lessonID,
    required this.lessonTitle,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      exerciseID: json['exerciseID'] ?? '',
      title: json['title'] ?? '',
      prompt: json['prompt'] ?? '',
      hints: json['hints'] ?? '',
      content: json['content'] ?? '',
      expectedAnswer: json['expectedAnswer'] ?? '',
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      mediaPublicIds: List<String>.from(json['mediaPublicIds'] ?? []),
      position: json['position'] ?? 0,
      exerciseType: json['exerciseType'] ?? '',
      difficulty: json['difficulty'] ?? '',
      maxScore: json['maxScore'] ?? 0,
      passScore: json['passScore'] ?? 0,
      feedbackCorrect: json['feedbackCorrect'] ?? '',
      feedbackIncorrect: json['feedbackIncorrect'] ?? '',
      courseID: json['courseID'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      unitID: json['unitID'] ?? '',
      unitTitle: json['unitTitle'] ?? '',
      lessonID: json['lessonID'] ?? '',
      lessonTitle: json['lessonTitle'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}