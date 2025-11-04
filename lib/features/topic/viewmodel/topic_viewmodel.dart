import 'package:get/get.dart';
import 'dart:async';

import '../data/repository.dart';
import '../data/service.dart';
import '../model/conversationLanguage.dart';
import '../model/topic.dart';

class TopicViewModel extends GetxController {
  final IRepository _authRepository;
  var isLoadingTopics = false.obs;
  var topics = <TopicModel>[].obs;

  var conversationLevels = <LanguageLevel>[].obs;
  var isLoadingLevels = false.obs;

  final _aiMessageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get aiMessageStream => _aiMessageController.stream;

  TopicViewModel(this._authRepository);

  Future<void> initSignalR() async {
    await _authRepository.initSignalR();
    if (_authRepository is service) {
      (_authRepository as service).onAiMessageReceived = (msg) {
        _aiMessageController.add(msg);
      };
    }
  }

  Future<void> disposeSignalR() async {
    await _authRepository.disposeSignalR();
    await _aiMessageController.close();
  }

  Future<void> sendConversationMessageSignalR({
    required String sessionId,
    required String messageContent,
    required int messageType,
    String? audioUrl,
    int? audioDuration,
    String? transcript,
  }) async {
    await _authRepository.sendConversationMessageSignalR(
      sessionId: sessionId,
      messageContent: messageContent,
      messageType: messageType,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
      transcript: transcript,
    );
  }

  Future<void> sendVoiceMessageSignalR({
    required String sessionId,
    required String audioUrl,
    required int audioDuration,
    String? transcript,
  }) async {
    await _authRepository.sendVoiceMessageSignalR(
      sessionId: sessionId,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
      transcript: transcript,
    );
  }

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

  Future<void> fetchConversationLevels(String languageId) async {
    try {
      isLoadingLevels.value = true;
      final list = await _authRepository.getConversationLevels(languageId);
      conversationLevels.assignAll(list);
    } catch (e) {
      print('fetchConversationLevels error: $e');
    } finally {
      isLoadingLevels.value = false;
    }
  }

  Future<void> joinConversationRoom(String sessionId) async {
    await _authRepository.joinConversationRoom(sessionId);
  }
}