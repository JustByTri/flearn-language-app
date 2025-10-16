import 'package:get/get.dart';

import '../data/repository.dart';
import '../model/topic.dart';



class TopicViewModel extends GetxController {
  final IRepository _authRepository;
  var isLoadingTopics = false.obs;
  var topics = <TopicModel>[].obs;

  TopicViewModel(this._authRepository);

  Future<void> fetchTopics() async {
    try {
      isLoadingTopics.value = true;
      final list = await _authRepository.getTopic();
      topics.assignAll(list);
    } catch (e) {
      print('fetchTopics error: $e');
    } finally {
      isLoadingTopics.value = false;
    }
  }

  Future<Map<String, dynamic>?> startConversation({
    required String languageId,
    required String topicId,
    required String difficultyLevel,
  }) async {
    try {
      return await _authRepository.startConversation(
        languageId: languageId,
        topicId: topicId,
        difficultyLevel: difficultyLevel,
      );
    } catch (e) {
      print('startConversation error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendConversationMessage({
    required String sessionId,
    required String messageContent,
    required int messageType,
    String? audioUrl,
    String? audioPublicId,
    int? audioDuration,
  }) async {
    try {
      return await _authRepository.sendConversationMessage(
        sessionId: sessionId,
        messageContent: messageContent,
        messageType: messageType,
        audioUrl: audioUrl,
        audioPublicId: audioPublicId,
        audioDuration: audioDuration,
      );
    } catch (e) {
      print('sendConversationMessage error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendVoiceMessage({
    required String sessionId,
    required String audioFilePath,
    required int audioDuration,
    String? transcript,
  }) async {
    try {
      return await _authRepository.sendVoiceMessage(
        sessionId: sessionId,
        audioFilePath: audioFilePath,
        audioDuration: audioDuration,
        transcript: transcript,
      );
    } catch (e) {
      print('sendVoiceMessage error: $e');
      return null;
    }
  }

}