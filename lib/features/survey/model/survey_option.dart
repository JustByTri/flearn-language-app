class SurveyOptions {
  final bool success;
  final SurveyOptionsData data;
  final String message;

  SurveyOptions({
    required this.success,
    required this.data,
    required this.message,
  });

  factory SurveyOptions.fromJson(Map<String, dynamic> json) {
    return SurveyOptions(
      success: json['success'] ?? false,
      data: SurveyOptionsData.fromJson(json['data'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}

class SurveyOptionsData {
  final List<String> currentLevels;
  final List<String> learningStyles;
  final List<String> prioritySkills;
  final List<String> targetTimelines;
  final List<String> speakingChallenges;
  final List<String> preferredAccents;
  final List<ConfidenceLevel> confidenceLevels;

  SurveyOptionsData({
    required this.currentLevels,
    required this.learningStyles,
    required this.prioritySkills,
    required this.targetTimelines,
    required this.speakingChallenges,
    required this.preferredAccents,
    required this.confidenceLevels,
  });

  factory SurveyOptionsData.fromJson(Map<String, dynamic> json) {
    return SurveyOptionsData(
      currentLevels: List<String>.from(json['currentLevels'] ?? []),
      learningStyles: List<String>.from(json['learningStyles'] ?? []),
      prioritySkills: List<String>.from(json['prioritySkills'] ?? []),
      targetTimelines: List<String>.from(json['targetTimelines'] ?? []),
      speakingChallenges: List<String>.from(json['speakingChallenges'] ?? []),
      preferredAccents: List<String>.from(json['preferredAccents'] ?? []),
      confidenceLevels: (json['confidenceLevels'] as List<dynamic>?)
          ?.map((e) => ConfidenceLevel.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ConfidenceLevel {
  final int value;
  final String label;

  ConfidenceLevel({required this.value, required this.label});

  factory ConfidenceLevel.fromJson(Map<String, dynamic> json) {
    return ConfidenceLevel(
      value: json['value'] ?? 0,
      label: json['label'] ?? '',
    );
  }
}