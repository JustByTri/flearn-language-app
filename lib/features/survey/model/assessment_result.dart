class RecommendedCourse {
  final String courseId;
  final String courseName;
  final String level;
  final String matchReason;
  final String? goalName;
  final String userId;

  RecommendedCourse({
    required this.courseId,
    required this.courseName,
    required this.level,
    required this.matchReason,
    this.goalName,
    required this.userId,
  });

  factory RecommendedCourse.fromJson(Map<String, dynamic> json) {
    return RecommendedCourse(
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? '',
      level: json['level'] ?? '',
      matchReason: json['matchReason'] ?? '',
      goalName: json['goalName'],
      userId: json['userId'] ?? '',
    );
  }
}

class AssessmentResult {
  final String assessmentId;
  final String determinedLevel;
  final int overallScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final String languageId;
  final String languageName;
  final String learnerLanguageId;
  final String programId;
  final String programName;
  final int levelConfidence;
  final String assessmentCompleteness;
  final int pronunciationScore;
  final int fluencyScore;
  final int grammarScore;
  final int vocabularyScore;
  final String detailedFeedback;
  final String nextLevelRequirements;
  final List<RecommendedCourse> recommendedCourses;
  final String completedAt;

  AssessmentResult({
    required this.assessmentId,
    required this.determinedLevel,
    required this.overallScore,
    required this.strengths,
    required this.weaknesses,
    required this.languageId,
    required this.languageName,
    required this.learnerLanguageId,
    required this.programId,
    required this.programName,
    required this.levelConfidence,
    required this.assessmentCompleteness,
    required this.pronunciationScore,
    required this.fluencyScore,
    required this.grammarScore,
    required this.vocabularyScore,
    required this.detailedFeedback,
    required this.nextLevelRequirements,
    required this.recommendedCourses,
    required this.completedAt,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      assessmentId: json['assessmentId'] ?? '',
      determinedLevel: json['determinedLevel'] ?? '',
      overallScore: json['overallScore'] ?? 0,
      strengths: List<String>.from(json['keyStrengths'] ?? []),
      weaknesses: List<String>.from(json['improvementAreas'] ?? []),
      languageId: json['laguageID'] ?? '', // chú ý typo từ API
      languageName: json['languageName'] ?? '',
      learnerLanguageId: json['learnerLanguageId'] ?? '',
      programId: json['programId'] ?? '',
      programName: json['programName'] ?? '',
      levelConfidence: json['levelConfidence'] ?? 0,
      assessmentCompleteness: json['assessmentCompleteness'] ?? '',
      pronunciationScore: json['pronunciationScore'] ?? 0,
      fluencyScore: json['fluencyScore'] ?? 0,
      grammarScore: json['grammarScore'] ?? 0,
      vocabularyScore: json['vocabularyScore'] ?? 0,
      detailedFeedback: json['detailedFeedback'] ?? '',
      nextLevelRequirements: json['nextLevelRequirements'] ?? '',
      recommendedCourses: (json['recommendedCourses'] as List<dynamic>? ?? [])
          .map((e) => RecommendedCourse.fromJson(e as Map<String, dynamic>))
          .toList(),
      completedAt: json['completedAt'] ?? '',
    );
  }
}