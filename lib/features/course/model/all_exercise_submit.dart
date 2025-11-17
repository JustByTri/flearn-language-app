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
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ExerciseSubmission(
      exerciseSubmissionId: json['exerciseSubmissionId'] ?? '',
      aiScore: parseInt(json['aiScore']),
      aiFeedback: json['aiFeedback'] ?? '',
      teacherScore: parseInt(json['teacherScore']),
      teacherFeedback: json['teacherFeedback'] ?? '',
      finalScore: parseInt(json['finalScore']),
      isPassed: json['isPassed'] ?? false,
      status: json['status'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      submittedAt: json['submittedAt'] ?? '',
    );
  }
}