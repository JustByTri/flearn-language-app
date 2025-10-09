class AssessmentResult {
  final String assessmentId;
  final String determinedLevel;
  final int overallScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final String languageId;
  final String languageName;
  final String learnerLanguageId;
  final int goalId;
  final String goalName;
  final bool requiresAcceptance;
  final List<dynamic> recommendedCourses;
  final bool hasRecommendedCourses;
  final int coursesCount;
  final bool hasCoursesForLevel;

  AssessmentResult({
    required this.assessmentId,
    required this.determinedLevel,
    required this.overallScore,
    required this.strengths,
    required this.weaknesses,
    required this.languageId,
    required this.languageName,
    required this.learnerLanguageId,
    required this.goalId,
    required this.goalName,
    required this.requiresAcceptance,
    required this.recommendedCourses,
    required this.hasRecommendedCourses,
    required this.coursesCount,
    required this.hasCoursesForLevel,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      assessmentId: json['assessmentId'] ?? '',
      determinedLevel: json['determinedLevel'] ?? '',
      overallScore: json['overallScore'] ?? 0,
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      languageId: json['languageId'] ?? '',
      languageName: json['languageName'] ?? '',
      learnerLanguageId: json['learnerLanguageId'] ?? '',
      goalId: json['goalId'] ?? 0,
      goalName: json['goalName'] ?? '',
      requiresAcceptance: json['requiresAcceptance'] ?? false,
      recommendedCourses: json['recommendedCourses'] ?? [],
      hasRecommendedCourses: json['hasRecommendedCourses'] ?? false,
      coursesCount: json['coursesCount'] ?? 0,
      hasCoursesForLevel: json['hasCoursesForLevel'] ?? false,
    );
  }
}