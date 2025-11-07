import 'package:get/get.dart';
import 'dart:async';

import '../data/repository.dart';
import '../data/service.dart';
import '../model/conversationLanguage.dart';
import '../model/topic.dart';

class TopicViewModel extends GetxController {
  final IRepository _authRepository;
  TopicViewModel(this._authRepository);

  // UI states
  var isLoadingTopics = false.obs;
  var topics = <TopicModel>[].obs;

  var conversationLevels = <LanguageLevel>[].obs;
  var isLoadingLevels = false.obs;

  var conversationUsage = Rxn<Map<String, dynamic>>();
  var isLoadingConversationUsage = false.obs;

  // Stream broadcast cho AI message
  final _aiMessageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get aiMessageStream => _aiMessageController.stream;

  bool _signalRInitialized = false;
  bool _callbacksWired = false;

  Future<void> initSignalR() async {
    if (!_signalRInitialized) {
      await _authRepository.initSignalR();
      _signalRInitialized = true;
      print('[VM] SignalR initialized');
    }
    _wireServiceCallbacksIfNeeded();
  }

  void _wireServiceCallbacksIfNeeded() {
    if (_callbacksWired) return;
    if (_authRepository is service) {
      final svc = _authRepository as service;
      svc.onAiMessageReceived = (msg) {
        // msg đã là Map<String, dynamic> (service đã chuẩn hóa)
        if (!_aiMessageController.isClosed) {
          print('[VM] onAiMessageReceived -> $msg');
          _aiMessageController.add(msg);
        } else {
          print('[VM] aiMessageController closed, drop msg');
        }
      };
      _callbacksWired = true;
      print('[VM] Service callbacks wired');
    } else {
      print('[VM] Repository is not concrete service; cannot wire AI callback');
    }
  }

  Future<void> disposeSignalR() async {
    await _authRepository.disposeSignalR();
    _signalRInitialized = false;
    _callbacksWired = false; // lần sau init sẽ gắn lại callback
    print('[VM] SignalR disposed');
    // KHÔNG close _aiMessageController ở đây
  }

  @override
  void onClose() {
    if (!_aiMessageController.isClosed) {
      _aiMessageController.close();
    }
    super.onClose();
  }

  // ---------- Bridge methods ----------
  Future<void> sendConversationMessageSignalR({
    required String sessionId,
    required String messageContent,
    required String messageType,
  }) async {
    await _authRepository.sendConversationMessageSignalR(
      sessionId: sessionId,
      messageContent: messageContent,
      messageType: messageType,
    );
  }

  Future<void> sendVoiceMessageSignalR({
    required String sessionId,
    required String audioUrl,
    required int audioDuration,
  }) async {
    await _authRepository.sendVoiceMessageSignalR(
      sessionId: sessionId,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
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
      final safeTranscript = (transcript == null || transcript.trim().isEmpty || transcript == 'string') ? null : transcript;
      return await _authRepository.sendVoiceMessage(
        sessionId: sessionId,
        audioFilePath: audioFilePath,
        audioDuration: audioDuration,
        transcript: safeTranscript,
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

  Future<void> sendVoiceMessageBase64SignalR({
    required String sessionId,
    required String base64Audio,
    required String mimeType,
    required int audioDuration,
  }) => _authRepository.sendVoiceMessageBase64SignalR(
    sessionId: sessionId,
    base64Audio: base64Audio,
    mimeType: mimeType,
    audioDuration: audioDuration,
  );

  Future<void> fetchConversationUsage() async {
    try {
      isLoadingConversationUsage.value = true;
      final usage = await _authRepository.fetchConversationUsage();
      conversationUsage.value = usage;
      print('fetchConversationUsage: $usage');
    } catch (e) {
      print('fetchConversationUsage error: $e');
      conversationUsage.value = null;
    } finally {
      isLoadingConversationUsage.value = false;
    }
  }

  int get remainingToday => conversationUsage.value?['remainingToday'] ?? 0;
  int get dailyLimit => conversationUsage.value?['dailyLimit'] ?? 0;
}