import '../model/conversationLanguage.dart';
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

  Future<List<LanguageLevel>> getConversationLevels(String languageId);
  Future<void> initSignalR();
  Future<void> disposeSignalR();
  Future<void> joinConversationRoom(String sessionId);
  Future<void> sendConversationMessageSignalR({
    required String sessionId,
    required String messageContent,
    required String messageType,
  });
  Future<void> sendVoiceMessageSignalR({
    required String sessionId,
    required String audioUrl,
    required int audioDuration,
  });
  Future<void> sendVoiceMessageBase64SignalR({
    required String sessionId,
    required String base64Audio,
    required String mimeType,
    required int audioDuration,
  });

  Future<Map<String, dynamic>?> fetchConversationUsage();
}