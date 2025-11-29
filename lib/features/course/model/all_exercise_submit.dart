// ...existing code...
class ExerciseSubmission {
  final String exerciseSubmissionId;
  final int aiScore;
  final int aiPercent;
  final String aiFeedback;
  final int teacherScore;
  final int teacherPercent;
  final String teacherFeedback;
  final int finalScore;
  final int? passScore;
  final bool isPassed;
  final String status;
  final String audioUrl;
  final String submittedAt;

  ExerciseSubmission({
    required this.exerciseSubmissionId,
    required this.aiScore,
    required this.aiPercent,
    required this.aiFeedback,
    required this.teacherScore,
    required this.teacherPercent,
    required this.teacherFeedback,
    required this.finalScore,
    this.passScore,
    required this.isPassed,
    required this.status,
    required this.audioUrl,
    required this.submittedAt,
  });

  factory ExerciseSubmission.fromJson(Map<String, dynamic> json) {
    return ExerciseSubmission(
      exerciseSubmissionId: json['exerciseSubmissionId'] as String? ?? '',
      aiScore: (json['aiScore'] as num?)?.toInt() ?? 0,
      aiPercent: (json['aiPercent'] as num?)?.toInt() ?? 0,
      aiFeedback: json['aiFeedback'] as String? ?? '',
      teacherScore: (json['teacherScore'] as num?)?.toInt() ?? 0,
      teacherPercent: (json['teacherPercent'] as num?)?.toInt() ?? 0,
      teacherFeedback: json['teacherFeedback'] as String? ?? '',
      finalScore: (json['finalScore'] as num?)?.toInt() ?? 0,
      passScore: json.containsKey('passScore') && json['passScore'] != null
          ? (json['passScore'] as num).toInt()
          : null,
      isPassed: json['isPassed'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      submittedAt: json['submittedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseSubmissionId': exerciseSubmissionId,
    'aiScore': aiScore,
    'aiPercent': aiPercent,
    'aiFeedback': aiFeedback,
    'teacherScore': teacherScore,
    'teacherPercent': teacherPercent,
    'teacherFeedback': teacherFeedback,
    'finalScore': finalScore,
    'passScore': passScore,
    'isPassed': isPassed,
    'status': status,
    'audioUrl': audioUrl,
    'submittedAt': submittedAt,
  };
}
