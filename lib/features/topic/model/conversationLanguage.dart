class ConversationLanguageResponse {
  final bool success;
  final String message;
  final List<ConversationLanguage> data;

  ConversationLanguageResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ConversationLanguageResponse.fromJson(Map<String, dynamic> json) {
    return ConversationLanguageResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => ConversationLanguage.fromJson(e))
          .toList(),
    );
  }
}

class ConversationLanguage {
  final String languageId;
  final String languageName;
  final String languageCode;
  final List<String> availableLevels;

  ConversationLanguage({
    required this.languageId,
    required this.languageName,
    required this.languageCode,
    required this.availableLevels,
  });

  factory ConversationLanguage.fromJson(Map<String, dynamic> json) {
    return ConversationLanguage(
      languageId: json['languageId'] ?? '',
      languageName: json['languageName'] ?? '',
      languageCode: json['languageCode'] ?? '',
      availableLevels: (json['availableLevels'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}