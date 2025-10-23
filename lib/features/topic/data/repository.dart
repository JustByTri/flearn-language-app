import '../model/topic.dart';

abstract class IRepository{
  Future<List<TopicModel>> getTopic();

  Future<Map<String, dynamic>?> startConversation({
    required String languageId,
    required String topicId,
    required String difficultyLevel,
  });

  Future<Map<String, dynamic>?> sendConversationMessage({
    required String sessionId,
    required String messageContent,
    required int messageType,
    String? audioUrl,
    String? audioPublicId,
    int? audioDuration,
  });

  Future<Map<String, dynamic>?> sendVoiceMessage({
    required String sessionId,
    required String audioFilePath,
    required int audioDuration,
    String? transcript,
  });

  Future<Map<String, dynamic>?> getConversationHistory();
}