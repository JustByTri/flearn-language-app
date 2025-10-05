class SurveyStatus {
  final bool hasCompletedSurvey;
  final bool needsOnboarding;
  final Map<String, dynamic>? survey;

  SurveyStatus({
    required this.hasCompletedSurvey,
    required this.needsOnboarding,
    this.survey,
  });

  factory SurveyStatus.fromJson(Map<String, dynamic> json) {
    return SurveyStatus(
      hasCompletedSurvey: json['hasCompletedSurvey'] ?? false,
      needsOnboarding: json['needsOnboarding'] ?? true,
      survey: json['survey'],
    );
  }
}