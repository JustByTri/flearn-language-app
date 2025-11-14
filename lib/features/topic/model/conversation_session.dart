class ConversationSessionModel {
  final String sessionId;
  final String sessionName;
  final String languageName;
  final String topicName;
  final String difficultyLevel;
  final String characterRole;
  final String scenarioDescription;
  final List<ConversationMessage> messages;
  final int status;
  final DateTime startedAt;
  final double? overallScore;
  final String? aiFeedback;
  final List<dynamic> tasks;

  ConversationSessionModel({
    required this.sessionId,
    required this.sessionName,
    required this.languageName,
    required this.topicName,
    required this.difficultyLevel,
    required this.characterRole,
    required this.scenarioDescription,
    required this.messages,
    required this.status,
    required this.startedAt,
    this.overallScore,
    this.aiFeedback,
    required this.tasks,
  });

  factory ConversationSessionModel.fromJson(Map<String, dynamic> json) {
    return ConversationSessionModel(
      sessionId: json['sessionId'] ?? '',
      sessionName: json['sessionName'] ?? '',
      languageName: json['languageName'] ?? '',
      topicName: json['topicName'] ?? '',
      difficultyLevel: json['difficultyLevel'] ?? '',
      characterRole: json['characterRole'] ?? '',
      scenarioDescription: json['scenarioDescription'] ?? '',
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((e) => ConversationMessage.fromJson(e))
          .toList(),
      status: json['status'] ?? 0,
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ?? DateTime.now(),
      overallScore: json['overallScore'] != null
          ? double.tryParse(json['overallScore'].toString())
          : null,
      aiFeedback: json['aiFeedback'],
      tasks: json['tasks'] ?? [],
    );
  }
}

class ConversationMessage {
  final String messageId;
  final int sender;
  final String messageContent;
  final int messageType;
  final String? audioUrl;
  final String? audioPublicId;
  final String? transcript;
  final int? audioDuration;
  final int sequenceOrder;
  final DateTime sentAt;
  final bool isVoiceMessage;
  final String formattedDuration;

  ConversationMessage({
    required this.messageId,
    required this.sender,
    required this.messageContent,
    required this.messageType,
    this.audioUrl,
    this.audioPublicId,
    this.audioDuration,
    this.transcript,
    required this.sequenceOrder,
    required this.sentAt,
    required this.isVoiceMessage,
    required this.formattedDuration,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      messageId: json['messageId'] ?? '',
      sender: json['sender'] ?? 0,
      messageContent: json['messageContent'] ?? '',
      messageType: json['messageType'] ?? 0,
      audioUrl: json['audioUrl'],
      transcript: json['transcript'],
      audioPublicId: json['audioPublicId'],
      audioDuration: json['audioDuration'],
      sequenceOrder: json['sequenceOrder'] ?? 0,
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
      isVoiceMessage: json['isVoiceMessage'] ?? false,
      formattedDuration: json['formattedDuration'] ?? '',
    );
  }
}
