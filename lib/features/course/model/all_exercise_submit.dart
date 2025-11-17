class ExerciseSubmission {
  final String exerciseSubmissionId;
  final int aiScore;
  final String aiFeedback;
  final int teacherScore;
  final String teacherFeedback;
  final int finalScore;
  final bool isPassed;
  final String status;
  final String audioUrl;
  final String submittedAt;

  ExerciseSubmission({
    required this.exerciseSubmissionId,
    required this.aiScore,
    required this.aiFeedback,
    required this.teacherScore,
    required this.teacherFeedback,
    required this.finalScore,
    required this.isPassed,
    required this.status,
    required this.audioUrl,
    required this.submittedAt,
  });

  factory ExerciseSubmission.fromJson(Map<String, dynamic> json) {
    return ExerciseSubmission(
      exerciseSubmissionId: json['exerciseSubmissionId'] ?? '',
      aiScore: json['aiScore'] ?? 0,
      aiFeedback: json['aiFeedback'] ?? '',
      teacherScore: json['teacherScore'] ?? 0,
      teacherFeedback: json['teacherFeedback'] ?? '',
      finalScore: json['finalScore'] ?? 0,
      isPassed: json['isPassed'] ?? false,
      status: json['status'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      submittedAt: json['submittedAt'] ?? '',
    );
  }
}