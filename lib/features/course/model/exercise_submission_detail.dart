// ...existing code...
class ExerciseSubmissionDetail {
  final String? exerciseSubmissionId;
  final String? exerciseId;
  final String? exerciseTitle;
  final String? exerciseDescription;
  final String? exerciseType;
  final int? passScore;
  final String? audioUrl;
  final String? submittedAt;
  final String? status;
  final int? aiScore;
  final String? aiFeedback;   // nullable & safe-string
  final String? transcript;   // nullable
  final int? teacherScore;
  final String? teacherFeedback;
  final int? finalScore;
  final bool? isPassed;
  final String? reviewedAt;
  final String? lessonId;
  final String? lessonTitle;
  final String? unitId;
  final String? unitTitle;
  final String? courseId;
  final String? courseTitle;
  final String? teacherId;
  final String? teacherName;
  final String? teacherAvatar;

  ExerciseSubmissionDetail({
    this.exerciseSubmissionId,
    this.exerciseId,
    this.exerciseTitle,
    this.exerciseDescription,
    this.exerciseType,
    this.passScore,
    this.audioUrl,
    this.submittedAt,
    this.status,
    this.aiScore,
    this.aiFeedback,
    this.transcript,
    this.teacherScore,
    this.teacherFeedback,
    this.finalScore,
    this.isPassed,
    this.reviewedAt,
    this.lessonId,
    this.lessonTitle,
    this.unitId,
    this.unitTitle,
    this.courseId,
    this.courseTitle,
    this.teacherId,
    this.teacherName,
    this.teacherAvatar,
  });

  static String? _s(dynamic v) => v == null ? null : v.toString();
  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }
  static bool? _b(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final t = v.toString().toLowerCase();
    if (t == 'true') return true;
    if (t == 'false') return false;
    return null;
  }

  factory ExerciseSubmissionDetail.fromJson(Map<String, dynamic> json) {
    return ExerciseSubmissionDetail(
      exerciseSubmissionId: _s(json['exerciseSubmissionId']),
      exerciseId: _s(json['exerciseId']),
      exerciseTitle: _s(json['exerciseTitle']),
      exerciseDescription: _s(json['exerciseDescription']),
      exerciseType: _s(json['exerciseType']),
      passScore: _i(json['passScore']),
      audioUrl: _s(json['audioUrl']),
      submittedAt: _s(json['submittedAt']),
      status: _s(json['status']),
      aiScore: _i(json['aiScore']),
      aiFeedback: _s(json['aiFeedback']),
      transcript: _s(json['transcript']),
      teacherScore: _i(json['teacherScore']),
      teacherFeedback: _s(json['teacherFeedback']),
      finalScore: _i(json['finalScore']),
      isPassed: _b(json['isPassed']),
      reviewedAt: _s(json['reviewedAt']),
      lessonId: _s(json['lessonId']),
      lessonTitle: _s(json['lessonTitle']),
      unitId: _s(json['unitId']),
      unitTitle: _s(json['unitTitle']),
      courseId: _s(json['courseId']),
      courseTitle: _s(json['courseTitle']),
      teacherId: _s(json['teacherId']),
      teacherName: _s(json['teacherName']),
      teacherAvatar: _s(json['teacherAvatar']),
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseSubmissionId': exerciseSubmissionId,
    'exerciseId': exerciseId,
    'exerciseTitle': exerciseTitle,
    'exerciseDescription': exerciseDescription,
    'exerciseType': exerciseType,
    'passScore': passScore,
    'audioUrl': audioUrl,
    'submittedAt': submittedAt,
    'status': status,
    'aiScore': aiScore,
    'aiFeedback': aiFeedback,
    'transcript': transcript,
    'teacherScore': teacherScore,
    'teacherFeedback': teacherFeedback,
    'finalScore': finalScore,
    'isPassed': isPassed,
    'reviewedAt': reviewedAt,
    'lessonId': lessonId,
    'lessonTitle': lessonTitle,
    'unitId': unitId,
    'unitTitle': unitTitle,
    'courseId': courseId,
    'courseTitle': courseTitle,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'teacherAvatar': teacherAvatar,
  };
}
// ...existing code...