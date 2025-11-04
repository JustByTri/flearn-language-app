class LanguageLevelResponse {
  final bool success;
  final List<LanguageLevel> data;

  LanguageLevelResponse({
    required this.success,
    required this.data,
  });

  factory LanguageLevelResponse.fromJson(Map<String, dynamic> json) {
    return LanguageLevelResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => LanguageLevel.fromJson(e))
          .toList(),
    );
  }
}

class LanguageLevel {
  final String languageLevelID;
  final String levelName;
  final String description;
  final int orderIndex;

  LanguageLevel({
    required this.languageLevelID,
    required this.levelName,
    required this.description,
    required this.orderIndex,
  });

  factory LanguageLevel.fromJson(Map<String, dynamic> json) {
    return LanguageLevel(
      languageLevelID: json['languageLevelID'] ?? '',
      levelName: json['levelName'] ?? '',
      description: json['description'] ?? '',
      orderIndex: json['orderIndex'] ?? 0,
    );
  }
}