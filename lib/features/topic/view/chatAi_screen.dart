import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flearn_app/features/topic/viewmodel/topic_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/constants/colors.dart';
import '../../topic/model/topic.dart';
import '../model/conversation_session.dart';
import 'conversation_result_screen.dart';

class ChatScreen extends StatefulWidget {
  final TopicModel topic;
  final Map<String, dynamic> conversationData;

  const ChatScreen({
    super.key,
    required this.topic,
    required this.conversationData,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
enum RecordingState { idle, recording, paused }

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _topicViewModel = Get.find<TopicViewModel>();
  final FocusNode _textFocusNode = FocusNode();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isRecording = false;
  bool _isTyping = false;
  bool _isEnding = false;
  String? _sessionId;
  ConversationSessionModel? _sessionModel;

  RecordingState _recordingState = RecordingState.idle;
  String? _pausedRecordingPath;
  Duration _recordingDuration = Duration.zero;

  Timer? _recordingTimer;
  bool _showRecordingOverlay = false;
  int _waveformBarsCount = 0;

  ChatMessage? _playingVoiceMessage;
  int _playingVoiceProgress = 0;
  Timer? _voicePlaybackTimer;
  StreamSubscription? _voiceCompletionSub;
  Duration _currentPlaybackPosition = Duration.zero;

  final Set<ChatMessage> _translatedMessages = {};
  bool _isRoleTranslated = false;
  final GoogleTranslator _translator = GoogleTranslator();
  Map<int, bool> _isTranslatingMessage = {};
  Map<int, String?> _translatedMessageText = {};

  Offset _taskButtonPosition = Offset(Get.width - 80, Get.height - 250);
  Map<int, bool> _isTranslatingTask = {};
  Map<int, String?> _translatedTaskText = {};


  bool _isHeaderVisible = true;
  bool _isTextMode = false;

  StreamSubscription<Map<String, dynamic>>? _aiSub;

  // Thêm trạng thái hiển thị transcript inline cho từng message voice. Khi nhấn icon, transcript sẽ hiện/ẩn ngay dưới voice bubble, không hiện pop-up.
  Map<int, bool> _showTranscript = {};
  Map<int, String?> _translatedVoice = {};

  bool _isSendingVoice = false; // Thêm biến trạng thái gửi voice
  Timer? _aiResponseTimeout; // Timeout cho AI response từ SignalR

  // NEW: cờ theo dõi AI reply cho voice
  bool _awaitingVoiceAi = false;
  bool _voiceAiReceived = false;

  // TTS state
  int? _speakingMessageIndex;
  bool _isTtsInitialized = false;

  // Auto speak flags
  bool _autoSpeakOnStart = true; // bật/tắt tự đọc khi bắt đầu chat
  bool _hasAutoSpokenInitial = false; // đảm bảo chỉ đọc 1 lần

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      // Thử khởi tạo TTS với timeout
      await _flutterTts.setLanguage("en-US").timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('TTS initialization timeout');
        },
      );

      await _flutterTts.setSpeechRate(0.5); // Tốc độ đọc (0.0 - 1.0)
      await _flutterTts.setVolume(1.0); // Âm lượng (0.0 - 1.0)
      await _flutterTts.setPitch(1.0); // Cao độ giọng nói

      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _speakingMessageIndex = null;
          });
        }
      });

      _flutterTts.setErrorHandler((msg) {
        print('[TTS] Error: $msg');
        if (mounted) {
          setState(() {
            _speakingMessageIndex = null;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isTtsInitialized = true;
        });
      }
      print('[TTS] Initialized successfully');
    } catch (e) {
      print('[TTS] Initialization error: $e');
      if (mounted) {
        setState(() {
          _isTtsInitialized = false;
        });
      }
      // Không hiển thị snackbar ở đây, sẽ hiển thị khi user thực sự muốn dùng
    }
  }

  Future<void> _speakText(String text, int messageIndex) async {
    // Thử khởi tạo lại nếu chưa sẵn sàng
    if (!_isTtsInitialized) {
      print('[TTS] Not initialized, attempting to initialize...');
      await _initializeTts();

      if (!_isTtsInitialized) {
        Get.snackbar('Lỗi', 'Không thể khởi tạo Text-to-Speech. Vui lòng thử lại.');
        return;
      }
    }

    // Nếu đang đọc message này, dừng lại
    if (_speakingMessageIndex == messageIndex) {
      await _flutterTts.stop();
      setState(() {
        _speakingMessageIndex = null;
      });
      return;
    }

    // Nếu đang đọc message khác, dừng trước khi đọc message mới
    if (_speakingMessageIndex != null) {
      await _flutterTts.stop();
    }

    setState(() {
      _speakingMessageIndex = messageIndex;
    });

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('[TTS] Speak error: $e');
      Get.snackbar('Lỗi', 'Không thể đọc văn bản');
      setState(() {
        _speakingMessageIndex = null;
      });
    }
  }

  Future<bool> _waitForTtsReady({Duration timeout = const Duration(seconds: 5)}) async {
    if (_isTtsInitialized) return true;
    await _initializeTts();
    final start = DateTime.now();
    while (!_isTtsInitialized && DateTime.now().difference(start) < timeout) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return _isTtsInitialized;
  }

  Future<void> _autoSpeakFirstAiText() async {
    if (_hasAutoSpokenInitial || !_autoSpeakOnStart) return;
    // tìm tin nhắn AI dạng text đầu tiên
    final idx = _messages.indexWhere((m) => !m.isUser && !m.isVoice && m.text.trim().isNotEmpty);
    if (idx < 0) return;

    final ready = await _waitForTtsReady();
    if (!ready) return;

    _hasAutoSpokenInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakText(_messages[idx].text, idx));
  }

  Future<void> _initializeChat() async {
    _requestPermissions();
    _sessionModel = ConversationSessionModel.fromJson(widget.conversationData);
    _sessionId = _sessionModel?.sessionId;

    for (final msg in _sessionModel?.messages ?? []) {
      _addMessage(ChatMessage(
        text: msg.messageContent,
        isUser: msg.sender == 1,
        timestamp: msg.sentAt,
      ));
    }

    await _topicViewModel.initSignalR();
    print('SignalR connected in ChatScreen');

    _aiSub = _topicViewModel.aiMessageStream.listen((aiMsg) {
      print('[AI STREAM] payload: $aiMsg');
      if (!mounted) return;

      // Chuẩn hóa field
      final content = aiMsg['content'] ?? aiMsg['messageContent'] ?? '';
      final ts = DateTime.tryParse(aiMsg['timestamp'] ?? aiMsg['sentAt'] ?? '') ?? DateTime.now();
      final senderRaw = aiMsg['sender'];
      final senderStr = senderRaw?.toString().toLowerCase();
      final isAi = senderStr == 'ai' || senderRaw == 2;
      final isUserSender = senderStr == 'user' || senderRaw == 1;
      final messageTypeRaw = aiMsg['messageType'];
      final messageTypeStr = messageTypeRaw?.toString().toLowerCase();
      final audioUrl = aiMsg['audioUrl'];
      final audioDuration = aiMsg['audioDuration'] ?? 0;
      final transcript = aiMsg['transcript'];
      final synonymSuggestions = aiMsg['synonymSuggestions'];
      final hasAudio = audioUrl != null && audioUrl.toString().isNotEmpty;
      final isVoiceMsg = hasAudio || messageTypeStr == 'voice' || messageTypeRaw == 2 || aiMsg['isVoiceMessage'] == true;

      // 1) Cập nhật synonymSuggestions cho user TEXT (nếu hub đính kèm)
      if (synonymSuggestions != null && !isVoiceMsg && isUserSender) {
        print('[AI STREAM] Found synonymSuggestions: $synonymSuggestions');
        final idx = _messages.lastIndexWhere((m) => m.isUser && !m.isVoice);
        if (idx != -1) {
          setState(() {
            _messages[idx] = ChatMessage(
              text: _messages[idx].text,
              isUser: true,
              timestamp: _messages[idx].timestamp,
              isVoice: false,
              audioUrl: null,
              duration: null,
              synonymSuggestions: synonymSuggestions,
            );
          });
          print('[AI STREAM] Updated user message at index $idx with synonymSuggestions');
        }
      }

      // 2) VoiceMessageReceived từ User: cập nhật transcript/synonyms cho bubble voice của user
      if (isUserSender && isVoiceMsg) {
        if (transcript != null || synonymSuggestions != null) {
          final idx = _messages.lastIndexWhere(
                (m) => m.isUser && m.isVoice && (m.transcript == null || m.transcript!.isEmpty),
          );
          if (idx != -1) {
            setState(() {
              _messages[idx] = ChatMessage(
                text: _messages[idx].text,
                isUser: true,
                timestamp: _messages[idx].timestamp,
                isVoice: true,
                audioUrl: _messages[idx].audioUrl,
                duration: _messages[idx].duration,
                transcript: transcript?.toString() ?? _messages[idx].transcript,
                synonymSuggestions: synonymSuggestions ?? _messages[idx].synonymSuggestions,
              );
            });
            print('[AI STREAM] Updated user voice transcript/synonyms via hub');
          }
        }
        return; // Không thêm bubble mới
      }

      // 3) AI trả về (ưu tiên hiển thị từ hub)
      if (isAi && isVoiceMsg) {
        // AI voice
        _addMessage(ChatMessage(
          text: content,
          isUser: false,
          timestamp: ts,
          isVoice: true,
          audioUrl: audioUrl?.toString(),
          duration: audioDuration is int ? audioDuration : int.tryParse(audioDuration.toString()) ?? 0,
          transcript: transcript?.toString(),
          synonymSuggestions: null,
        ));
        setState(() => _isTyping = false);
        if (_awaitingVoiceAi) {
          _voiceAiReceived = true;
          _aiResponseTimeout?.cancel();
          _aiResponseTimeout = null;
          print('[VOICE][HUB] AI voice received');
        }
        return;
      }

      if (isAi && !isVoiceMsg) {
        // AI text
        _addMessage(ChatMessage(
          text: content,
          isUser: false,
          timestamp: ts,
          isVoice: false,
          audioUrl: null,
          duration: null,
          transcript: null,
          synonymSuggestions: null,
        ));
        setState(() => _isTyping = false);
        if (_awaitingVoiceAi) {
          _voiceAiReceived = true;
          _aiResponseTimeout?.cancel();
          _aiResponseTimeout = null;
          print('[VOICE][HUB] AI text received');
        }
        return;
      }
    }, onError: (e) {
      print('[AI STREAM] error: $e');
      if (mounted) setState(() => _isTyping = false);
    });

    if (_sessionId != null) {
      await _topicViewModel.joinConversationRoom(_sessionId!);
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  void _addMessage(ChatMessage message) {
    print('[UI] Add message: ${message.text} | isUser: ${message.isUser} | time: ${message.timestamp}');
    if (mounted) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    }

    // Kiểm tra và tự động đọc tin nhắn AI đầu tiên (nếu có)
    if (!message.isUser && !message.isVoice && message.text.trim().isNotEmpty) {
      _autoSpeakFirstAiText();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sessionId == null) return;

    _addMessage(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    _messageController.clear();
    setState(() => _isTyping = true);

    try {
      // Gọi SignalR để gửi realtime
      await _topicViewModel.sendConversationMessageSignalR(
        sessionId: _sessionId!,
        messageContent: text,
        messageType: "Text",
      );

      // Gọi HTTP API để lấy synonymSuggestions
      final httpResp = await _topicViewModel.sendConversationMessage(
        sessionId: _sessionId!,
        messageContent: text,
        messageType: 1, // 1 = Text
      );


      if (httpResp != null && httpResp['data'] != null) {
        final synonymSuggestions = httpResp['data']['synonymSuggestions'];
        if (synonymSuggestions != null) {
          print('[HTTP] Found synonymSuggestions: $synonymSuggestions');
          final idx = _messages.lastIndexWhere((m) => m.isUser && !m.isVoice && m.text == text);
          if (idx != -1) {
            setState(() {
              _messages[idx] = ChatMessage(
                text: text,
                isUser: true,
                timestamp: _messages[idx].timestamp,
                isVoice: false,
                audioUrl: null,
                duration: null,
                synonymSuggestions: synonymSuggestions,
              );
            });
            print('[HTTP] Updated user message at index $idx with synonymSuggestions');
          }
        }
      }
    } catch (e) {
      setState(() => _isTyping = false);
      Get.snackbar("Lỗi", "Không thể gửi tin nhắn: $e");
    }
  }

  Future<void> _handleRecording() async {
    if (_recordingState == RecordingState.recording) {

      await _pauseRecording();
    } else if (_recordingState == RecordingState.paused) {

    } else {

      await _startRecording();
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    setState(() => _waveformBarsCount = 0);

    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_recordingState == RecordingState.recording) {
        setState(() {
          _recordingDuration = Duration(milliseconds: _recordingDuration.inMilliseconds + 100);


          if (_waveformBarsCount < 35) {
            _waveformBarsCount++;
          }
        });
      }
    });
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      Get.snackbar("Lỗi", "Không có quyền ghi âm");
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/chat_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: filePath);
      setState(() {
        _isRecording = true;
        _recordingState = RecordingState.recording;
        _recordingDuration = Duration.zero;
        _showRecordingOverlay = true;
      });


      _startRecordingTimer();
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể bắt đầu ghi âm: $e");
    }
  }
  Future<void> _pauseRecording() async {
    try {
      _recordingTimer?.cancel();
      final path = await _recorder.stop();
      setState(() {
        _recordingState = RecordingState.paused;
        _pausedRecordingPath = path;
        _isRecording = false;
        _showRecordingOverlay = false;
      });
      if (path != null) {
        _showVoicePreviewBottomSheet();
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể dừng ghi âm: $e");
    }
  }

  Future<void> _confirmEndConversation() async {
    if (_sessionId == null) return;

    Get.dialog(
      CupertinoAlertDialog(
        title: const Text("Kết thúc Roleplay"),
        content: const Text("Bạn có chắc chắn muốn kết thúc cuộc trò chuyện này không?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Huỷ"),
            onPressed: () => Get.back(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Kết thúc"),
            onPressed: () {
              Get.back();
              _endConversation();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _endConversation() async {
    setState(() => _isEnding = true);
    try {
      final accessToken = GetStorage().read('accessToken');
      final url = Uri.parse('https://f-learn.app/api/conversation/$_sessionId/end');
      final response = await http.post(
        url,
        headers: {"Authorization": "Bearer $accessToken"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          Get.off(() => ConversationResultScreen(resultData: result['data']));
        } else {
          Get.snackbar("Lỗi", result['message'] ?? "Không thể lấy kết quả.");
        }
      } else {
        Get.snackbar("Lỗi", "Kết thúc thất bại: ${response.body}");
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Lỗi kết nối: $e");
    } finally {
      if(mounted) setState(() => _isEnding = false);
    }
  }


  @override
  void dispose() {
    _aiSub?.cancel();
    _aiResponseTimeout?.cancel(); // NEW
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    _textFocusNode.dispose();
    _recordingTimer?.cancel();
    _voicePlaybackTimer?.cancel();
    _voiceCompletionSub?.cancel();
    _flutterTts.stop();
    _topicViewModel.disposeSignalR();
    super.dispose();
  }

  String _getTranslatedText(String originalText, bool isTranslated) {
    if (!originalText.contains('|')) return originalText;
    final parts = originalText.split('|');
    final lang1 = parts[0].trim();
    final lang2 = parts.length > 1 ? parts[1].trim() : lang1;
    return isTranslated ? lang2 : lang1;
  }

  void _showTranslationMenu(ChatMessage message) {
    if (message.isUser || !message.text.contains('|')) return;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            )),
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(CupertinoIcons.text_bubble, color: AppColors.primary),
              title: const Text('Dịch nguyên câu', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Get.back();
                setState(() {
                  if (_translatedMessages.contains(message)) {
                    _translatedMessages.remove(message);
                  } else {
                    _translatedMessages.add(message);
                  }
                });
              },
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(CupertinoIcons.wand_stars, color: Colors.grey),
              title: Text('Dịch từ này'),
              subtitle: Text('Tính năng sắp ra mắt'),
              enabled: false,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEnding) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/endchat.gif', width: 180),
              const SizedBox(height: 30),
              Text(
                'Đang thu thập và phân tích kết quả...\nVui lòng đợi trong giây lát.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {

        _textFocusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _isHeaderVisible ? null : 0,
                  child: _isHeaderVisible ? _buildHeader() : const SizedBox.shrink(),
                ),
                Expanded(child: _buildChatBody()),
              ],
            ),
            if (_sessionModel?.tasks != null && _sessionModel!.tasks.isNotEmpty)
              _buildFloatingTaskButton(),
            if (_showRecordingOverlay) _buildRecordingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingTaskButton() {
    return Positioned(
      left: _taskButtonPosition.dx,
      top: _taskButtonPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {

            _taskButtonPosition = Offset(
              (_taskButtonPosition.dx + details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width - 70),
              (_taskButtonPosition.dy + details.delta.dy).clamp(0.0, MediaQuery.of(context).size.height - 70),
            );
          });
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.assignment, color: Colors.white, size: 28),
            onPressed: _showTasksDialog,
          ),
        ),
      ),
    );
  }

  void _showTasksDialog() {
    List<String> taskContents = [];
    if (_sessionModel?.tasks != null) {
      for (var task in _sessionModel!.tasks) {
        if (task is Map<String, dynamic> && task.containsKey('taskDescription') && task['taskDescription'] is String) {
          taskContents.add(task['taskDescription']);
        }
      }
    }

    if (taskContents.isEmpty) return;

    // Reset translation state khi mở dialog
    _isTranslatingTask.clear();
    _translatedTaskText.clear();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Nhiệm vụ của bạn",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...taskContents.asMap().entries.map((entry) {
                final index = entry.key;
                final taskContent = entry.value;
                return _buildTaskItem(index, taskContent);
              }),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
    );
  }

  Widget _buildTaskItem(int index, String taskContent) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        final isTranslating = _isTranslatingTask[index] ?? false;
        final translatedText = _translatedTaskText[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      taskContent,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: isTranslating
                    ? const CupertinoActivityIndicator()
                    : (translatedText != null)
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translatedText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                        height: 1.4,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          _translatedTaskText[index] = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: AppColors.primary, size: 16),
                      label: const Text('Ẩn dịch', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                    ),
                  ],
                )
                    : TextButton.icon(
                  onPressed: () async {
                    setDialogState(() {
                      _isTranslatingTask[index] = true;
                    });
                    try {
                      final translation = await _translator.translate(taskContent, to: 'vi');
                      setDialogState(() {
                        _translatedTaskText[index] = translation.text;
                      });
                    } catch (e) {
                      Get.snackbar('Lỗi', 'Dịch thất bại');
                    } finally {
                      setDialogState(() {
                        _isTranslatingTask[index] = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.translate, color: AppColors.primary, size: 16),
                  label: const Text('Dịch', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatBody() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.back, color: Colors.white, size: 26),
                  onPressed: () => Get.back(),
                ),
                TextButton(
                  onPressed: _confirmEndConversation,
                  child: const Text(
                    "Kết thúc",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          "Kịch bản: ${_sessionModel?.scenarioDescription ?? '...'}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.description, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showScenarioTranslation(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  GestureDetector(
                    onTap: () => setState(() => _isRoleTranslated = !_isRoleTranslated),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                        text: "Vai của bạn: ",
                        style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).toInt()), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: _getTranslatedText(_sessionModel?.characterRole ?? '...', _isRoleTranslated),
                        style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).toInt()), fontSize: 13),
                      )
                    ])),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showScenarioTranslation() {
    String? translatedScenario;
    bool isTranslatingScenario = false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Kịch bản",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _sessionModel?.scenarioDescription ?? '...',
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5),
                ),
                const SizedBox(height: 16),
                if (translatedScenario == null)
                  isTranslatingScenario
                      ? const Center(child: CupertinoActivityIndicator())
                      : TextButton.icon(
                    onPressed: () async {
                      setDialogState(() => isTranslatingScenario = true);
                      try {
                        final translation = await _translator.translate(
                          _sessionModel?.scenarioDescription ?? '',
                          to: 'vi',
                        );
                        setDialogState(() {
                          translatedScenario = translation.text;
                          isTranslatingScenario = false;
                        });
                      } catch (e) {
                        Get.snackbar('Lỗi', 'Dịch thất bại');
                        setDialogState(() => isTranslatingScenario = false);
                      }
                    },
                    icon: const Icon(Icons.translate, color: AppColors.primary),
                    label: const Text('Dịch sang tiếng Việt', style: TextStyle(color: AppColors.primary)),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.language, color: AppColors.primary, size: 18),
                          SizedBox(width: 8),
                          Text('Bản dịch:', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        translatedScenario!,
                        style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black87, height: 1.5),
                      ),
                      TextButton.icon(
                        onPressed: () => setDialogState(() => translatedScenario = null),
                        icon: const Icon(Icons.close, color: AppColors.primary, size: 18),
                        label: const Text('Ẩn dịch', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isVoice = message.isVoice;
    final isTranslated = _translatedMessages.contains(message);
    final hasTranslation = !isUser && message.text.contains('|');
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isUser ? AppColors.primary : const Color(0xFFF0F2F5);
    final textColor = isUser ? Colors.white : Colors.black87;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isUser ? 20 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 20),
    );
    final msgIndex = _messages.indexOf(message);
    final isVoiceTranslated = _translatedVoice.containsKey(msgIndex);

    return Column(
      crossAxisAlignment: align,
      children: [
        // --- HIỂN THỊ BUBBLE VOICE HOẶC BUBBLE DỊCH ---
        if (isVoice && isVoiceTranslated)
        // Hiển thị bubble text đã dịch với menu ở góc
          _buildTranslatedVoiceBubble(msgIndex, message, isUser)
        else if (isUser && isVoice && message.transcript != null && message.transcript!.isNotEmpty)
        // Hiển thị bubble voice user với menu ở góc dưới trái + bóng đèn ở góc trên phải
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                decoration: BoxDecoration(color: color, borderRadius: radius),
                child: _buildVoiceMessageContent(message, textColor),
              ),
              // Menu context ở góc dưới trái
              Positioned(
                bottom: 0,
                left: 0,
                child: _buildVoiceContextMenu(message, msgIndex, isUser),
              ),
              // Bóng đèn gợi ý ở góc trên phải
              if (message.synonymSuggestions != null)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showSynonymSuggestions(message.synonymSuggestions!),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lightbulb,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          )
        else if (!isUser && isVoice && message.transcript != null && message.transcript!.isNotEmpty)
          // Hiển thị bubble voice AI với menu ở góc dưới PHẢI
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                  decoration: BoxDecoration(color: color, borderRadius: radius),
                  child: _buildVoiceMessageContent(message, textColor),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildVoiceContextMenu(message, msgIndex, isUser),
                ),
              ],
            )
          else if (!isUser && !isVoice)
            // Hiển thị bubble text AI với menu dịch + đọc ở góc dưới phải (KHÔNG có bóng đèn)
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                    decoration: BoxDecoration(color: color, borderRadius: radius),
                    child: _buildTextMessageContent(message, isTranslated, hasTranslation, textColor),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildTextContextMenu(message, msgIndex),
                  ),
                ],
              )
            else if (isUser && !isVoice)
              // Hiển thị bubble text User với menu dịch ở góc dưới trái và bóng đèn ở góc trên phải
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                      decoration: BoxDecoration(color: color, borderRadius: radius),
                      child: _buildTextMessageContent(message, isTranslated, hasTranslation, textColor),
                    ),
                    // Menu context ở góc dưới trái
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: _buildUserTextContextMenu(message, msgIndex),
                    ),
                    // Bóng đèn gợi ý ở góc trên phải
                    if (message.synonymSuggestions != null)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showSynonymSuggestions(message.synonymSuggestions!),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lightbulb,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              else
              // Hiển thị bubble gốc (voice không có transcript hoặc trường hợp đặc biệt)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(maxWidth: Get.width * 0.75),
                  decoration: BoxDecoration(color: color, borderRadius: radius),
                  child: isVoice
                      ? _buildVoiceMessageContent(message, textColor)
                      : _buildTextMessageContent(message, isTranslated, hasTranslation, textColor),
                ),


        // Hiển thị transcript inline nếu được chọn và chưa bị dịch thay thế
        if (isUser && isVoice && !isVoiceTranslated && _showTranscript[msgIndex] == true)
          _buildInlineTranscript(message),

        // Hiển thị bản dịch inline cho text message (cả User và AI)
        if (!isVoice && _translatedMessageText[msgIndex] != null)
          _buildInlineTranslation(msgIndex, isUser),

        // --- HIỂN THỊ THỜI GIAN ---
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 5),
          child: Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // Widget cho Context Menu của text message (AI)
  Widget _buildTextContextMenu(ChatMessage message, int msgIndex) {
    final isTranslated = _translatedMessageText.containsKey(msgIndex);
    final isSpeaking = _speakingMessageIndex == msgIndex;

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'translate') {
          setState(() {
            _isTranslatingMessage[msgIndex] = true;
          });
          try {
            final translation = await _translator.translate(message.text, to: 'vi');
            if (mounted) {
              setState(() {
                _translatedMessageText[msgIndex] = translation.text;
                _isTranslatingMessage[msgIndex] = false;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isTranslatingMessage.remove(msgIndex);
              });
            }
            Get.snackbar('Lỗi', 'Không thể dịch tin nhắn.');
          }
        } else if (value == 'hide_translation') {
          setState(() {
            _translatedMessageText.remove(msgIndex);
          });
        } else if (value == 'read_aloud') {
          // Gọi hàm đọc TTS
          await _speakText(message.text, msgIndex);
        }
      },
      itemBuilder: (BuildContext context) {
        List<PopupMenuItem<String>> items = [];

        // Luôn có nút đọc (icon thay đổi khi đang đọc)
        items.add(
          PopupMenuItem<String>(
            value: 'read_aloud',
            child: Row(
              children: [
                Icon(
                    isSpeaking ? Icons.stop_circle : Icons.volume_up,
                    color: isSpeaking ? Colors.red.shade700 : Colors.blue.shade700,
                    size: 20
                ),
                const SizedBox(width: 12),
                Text(
                    isSpeaking ? 'Dừng đọc' : 'Đọc',
                    style: TextStyle(
                        color: isSpeaking ? Colors.red.shade700 : Colors.blue.shade700
                    )
                ),
              ],
            ),
          ),
        );

        if (isTranslated) {
          items.add(
            PopupMenuItem<String>(
              value: 'hide_translation',
              child: Row(
                children: [
                  Icon(Icons.close, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Text('Ẩn dịch', style: TextStyle(color: Colors.orange.shade700)),
                ],
              ),
            ),
          );
        } else {
          items.add(
            PopupMenuItem<String>(
              value: 'translate',
              child: Row(
                children: [
                  Icon(Icons.translate, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 12),
                  Text('Dịch', style: TextStyle(color: Colors.green.shade700)),
                ],
              ),
            ),
          );
        }

        return items;
      },
      padding: EdgeInsets.zero,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.9 * 255).toInt()),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isSpeaking ? Icons.graphic_eq : Icons.more_horiz,
          size: 16,
          color: isSpeaking ? Colors.blue : Colors.black54,
        ),
      ),
    );
  }

  // Widget cho Context Menu của text message (User)
  Widget _buildUserTextContextMenu(ChatMessage message, int msgIndex) {
    final isTranslated = _translatedMessageText.containsKey(msgIndex);

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'translate') {
          setState(() {
            _isTranslatingMessage[msgIndex] = true;
          });
          try {
            final translation = await _translator.translate(message.text, to: 'vi');
            if (mounted) {
              setState(() {
                _translatedMessageText[msgIndex] = translation.text;
                _isTranslatingMessage[msgIndex] = false;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isTranslatingMessage.remove(msgIndex);
              });
            }
            Get.snackbar('Lỗi', 'Không thể dịch tin nhắn.');
          }
        } else if (value == 'hide_translation') {
          setState(() {
            _translatedMessageText.remove(msgIndex);
          });
        }
      },
      itemBuilder: (BuildContext context) {
        if (isTranslated) {
          return [
            PopupMenuItem<String>(
              value: 'hide_translation',
              child: Row(
                children: [
                  Icon(Icons.close, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Text('Ẩn dịch', style: TextStyle(color: Colors.orange.shade700)),
                ],
              ),
            ),
          ];
        }

        return [
          PopupMenuItem<String>(
            value: 'translate',
            child: Row(
              children: [
                Icon(Icons.translate, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 12),
                Text('Dịch', style: TextStyle(color: Colors.green.shade700)),
              ],
            ),
          ),
        ];
      },
      padding: EdgeInsets.zero,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.9 * 255).toInt()),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.more_horiz, size: 16, color: Colors.black54),
      ),
    );
  }

  // Widget cho Context Menu của voice message
  Widget _buildVoiceContextMenu(ChatMessage message, int msgIndex, bool isUser) {
    final isTranslated = _translatedVoice.containsKey(msgIndex);

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'show_transcript') {
          setState(() {
            _showTranscript[msgIndex] = !(_showTranscript[msgIndex] ?? false);
          });
        } else if (value == 'translate') {
          setState(() {
            _translatedVoice[msgIndex] = 'translating...'; // Trạng thái đang dịch
          });
          try {
            final translation = await _translator.translate(message.transcript!, to: 'vi');
            if (mounted) {
              setState(() {
                _translatedVoice[msgIndex] = translation.text;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _translatedVoice.remove(msgIndex); // Xóa nếu dịch lỗi
              });
            }
            Get.snackbar('Lỗi', 'Không thể dịch transcript.');
          }
        } else if (value == 'undo_translate') {
          setState(() {
            _translatedVoice.remove(msgIndex);
          });
        }
      },
      itemBuilder: (BuildContext context) {
        // Nếu đã dịch, chỉ hiện tùy chọn hoàn tác
        if (isTranslated) {
          return [
            PopupMenuItem<String>(
              value: 'undo_translate',
              child: Row(
                children: [
                  Icon(Icons.undo, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Text('Hiện lại voice', style: TextStyle(color: Colors.orange.shade700)),
                ],
              ),
            ),
          ];
        }

        // Nếu chưa dịch, hiện 2 tùy chọn: xem transcript và dịch
        return [
          PopupMenuItem<String>(
            value: 'show_transcript',
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Text(
                  _showTranscript[msgIndex] == true ? 'Ẩn Transcript' : 'Xem Transcript',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'translate',
            child: Row(
              children: [
                Icon(Icons.translate, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 12),
                Text('Dịch Transcript', style: TextStyle(color: Colors.green.shade700)),
              ],
            ),
          ),
        ];
      },
      padding: EdgeInsets.zero,
      child: const Icon(Icons.more_horiz, size: 16, color: Colors.black54),
    );
  }

  // Widget hiển thị transcript inline
  Widget _buildInlineTranscript(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withAlpha((0.3 * 255).toInt())),
        ),
        child: Text(
          '"${message.transcript!}"',
          style: TextStyle(
            color: Colors.blue.shade800,
            fontStyle: FontStyle.italic,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // Widget hiển thị bản dịch inline cho text message
  Widget _buildInlineTranslation(int msgIndex, bool isUser) {
    final translatedText = _translatedMessageText[msgIndex];
    final isTranslating = _isTranslatingMessage[msgIndex] ?? false;

    return Padding(
      padding: isUser
          ? const EdgeInsets.fromLTRB(40, 4, 16, 8)  // User: padding trái nhiều hơn
          : const EdgeInsets.fromLTRB(16, 4, 40, 8),  // AI: padding phải nhiều hơn
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withAlpha((0.3 * 255).toInt())),
        ),
        child: isTranslating
            ? const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
            ),
            SizedBox(width: 8),
            Text('Đang dịch...', style: TextStyle(color: Colors.green, fontSize: 14)),
          ],
        )
            : Text(
          translatedText ?? '',
          style: TextStyle(
            color: Colors.green.shade800,
            fontStyle: FontStyle.italic,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // Widget hiển thị bubble text đã dịch (thay thế cho voice)
  Widget _buildTranslatedVoiceBubble(int msgIndex, ChatMessage message, bool isUser) {
    final translatedText = _translatedVoice[msgIndex];
    final isTranslating = translatedText == 'translating...';

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: Get.width * 0.75),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha((0.15 * 255).toInt()),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 20),
            ),
            border: Border.all(color: Colors.green.withAlpha((0.4 * 255).toInt())),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 10),
              if (isTranslating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                )
              else
                Flexible(
                  child: Text(
                    translatedText ?? 'Lỗi dịch',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: isUser ? 0 : null,
          right: isUser ? null : 0,
          child: _buildVoiceContextMenu(message, msgIndex, isUser),
        ),
      ],
    );
  }


  Widget _buildVoiceMessageContent(ChatMessage message, Color textColor) {
    final d = message.duration ?? 0;
    final isUser = message.isUser;
    final isPlaying = _playingVoiceMessage == message;

    // Hiển thị thời gian: nếu đang phát thì dùng position, nếu không thì dùng duration
    final displayDuration = isPlaying ? _currentPlaybackPosition : Duration(seconds: d);
    final mm = (displayDuration.inMinutes).toString();
    final ss = (displayDuration.inSeconds % 60).toString().padLeft(2, '0');

    // Tính số thanh dựa trên duration (giống preview)
    final totalBars = (d * 10 / 35).clamp(15, 35).toInt();

    return Container(
      padding: const EdgeInsets.all(0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: () => _playVoiceMessage(message),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUser ? Colors.white : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                color: isUser ? AppColors.primary : Colors.white,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Waveform với animation (giống preview)
          Expanded(
            child: SizedBox(
              height: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(
                  totalBars,
                      (index) {
                    final baseHeight = 18.0;
                    final variation = ((index * 3) % 4) * 4.0;
                    final height = baseHeight + variation;

                    // Highlight thanh đang phát
                    final isActive = isPlaying && index <= _playingVoiceProgress;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isUser ? Colors.white : AppColors.primary)
                            : (isUser ? Colors.white : AppColors.primary).withAlpha((0.3 * 255).toInt()),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                      height: height,
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),


          Text(
            '$mm:$ss',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessageContent(ChatMessage message, bool isTranslated, bool hasTranslation, Color textColor) {
    final displayText = _getTranslatedText(message.text, isTranslated);
    final words = displayText.split(' ');

    return RichText(
      text: TextSpan(
        style: TextStyle(color: textColor, fontSize: 16, height: 1.4),
        children: words.asMap().entries.map((entry) {
          int idx = entry.key;
          String word = entry.value;
          return TextSpan(
            text: idx == words.length - 1 ? word : "$word ",
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (hasTranslation) {
                  _showTranslationMenu(message);
                }
              },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTranslationButton(int msgIndex, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: _isTranslatingMessage[msgIndex] == true
          ? const CupertinoActivityIndicator()
          : (_translatedMessageText[msgIndex] != null)
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translatedMessageText[msgIndex]!,
            style: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
              height: 1.4,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _translatedMessageText[msgIndex] = null;
              });
            },
            icon: const Icon(Icons.close, color: AppColors.primary, size: 18),
            label: const Text('Ẩn dịch', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      )
          : TextButton.icon(
        onPressed: () async {
          setState(() {
            _isTranslatingMessage[msgIndex] = true;
          });
          try {
            final translation = await _translator.translate(message.text, to: 'vi');
            setState(() {
              _translatedMessageText[msgIndex] = translation.text;
            });
          } catch (e) {
            Get.snackbar('Lỗi', 'Dịch thất bại');
          } finally {
            setState(() {
              _isTranslatingMessage[msgIndex] = false;
            });
          }
        },
        icon: const Icon(Icons.translate, color: AppColors.primary, size: 18),
        label: const Text('Dịch', style: TextStyle(color: AppColors.primary)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value * 2).clamp(0.3, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildInputArea() {
    final hasText = _messageController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        top: false,
        child: _isTextMode
            ? _buildTextInputMode(hasText)
            : _buildVoiceInputMode(),
      ),
    );
  }

  Widget _buildTextInputMode(bool hasText) {
    return Row(
      children: [

        IconButton(
          icon: const Icon(Icons.mic, color: AppColors.primary, size: 28),
          onPressed: () {
            setState(() => _isTextMode = false);
            _textFocusNode.unfocus();
          },
        ),
        const SizedBox(width: 8),

        // Text input
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _messageController,
              focusNode: _textFocusNode,
              decoration: const InputDecoration(
                hintText: "Nhập tin nhắn...",
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: (_) {
                if (hasText) _sendMessage();
              },
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Nút gửi
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hasText ? AppColors.primary : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            onPressed: hasText ? _sendMessage : null,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceInputMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        const SizedBox(width: 48),


        GestureDetector(
          onTap: _handleRecording,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _recordingState == RecordingState.recording ? Colors.red : AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_recordingState == RecordingState.recording ? Colors.red : AppColors.primary).withAlpha((0.3 * 255).toInt()),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              _recordingState == RecordingState.recording ? Icons.pause : Icons.mic,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),


        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.keyboard, color: AppColors.textSecondary, size: 24),
            onPressed: () {
              setState(() => _isTextMode = true);
              Future.delayed(const Duration(milliseconds: 100), () {
                _textFocusNode.requestFocus();
              });
            },
          ),
        ),
      ],
    );
  }

  Future<void> _playVoiceMessage(ChatMessage message) async {
    if (message.audioUrl == null) return;

    // Nếu đang phát message này → Pause
    if (_playingVoiceMessage == message) {
      await _audioPlayer.pause();
      _voicePlaybackTimer?.cancel();
      setState(() {
        _playingVoiceMessage = null;
      });
      return;
    }

    // Stop message cũ nếu có
    if (_playingVoiceMessage != null) {
      await _audioPlayer.stop();
      _voicePlaybackTimer?.cancel();
    }

    // Play
    final src = message.audioUrl!;
    if (src.startsWith('http://') || src.startsWith('https://')) {
      await _audioPlayer.play(UrlSource(src));
    } else {
      await _audioPlayer.play(DeviceFileSource(src));
    }

    // Tính số thanh dựa trên duration
    final totalBars = ((message.duration ?? 0) * 10 / 35).clamp(15, 35).toInt();

    // Reset position
    _currentPlaybackPosition = Duration.zero;

    // Bắt đầu animation + update position
    _playingVoiceProgress = 0;
    _voicePlaybackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          // Update progress bar
          _playingVoiceProgress++;
          if (_playingVoiceProgress >= totalBars) {
            _playingVoiceProgress = 0; // Loop lại
          }

          // Update thời gian hiển thị
          _currentPlaybackPosition = Duration(milliseconds: _currentPlaybackPosition.inMilliseconds + 100);
        });
      }
    });

    // Listen khi audio phát xong
    _voiceCompletionSub?.cancel();
    _voiceCompletionSub = _audioPlayer.onPlayerComplete.listen((_) {
      _voicePlaybackTimer?.cancel();
      if (mounted) {
        setState(() {
          _playingVoiceMessage = null;
          _playingVoiceProgress = 0;
          _currentPlaybackPosition = Duration.zero;
        });
      }
    });

    setState(() {
      _playingVoiceMessage = message;
    });
  }

  void _showVoicePreviewBottomSheet() {
    bool isPlaying = false;
    Timer? playbackTimer;
    int playbackProgress = 0;
    Duration currentPosition = Duration.zero;
    StreamSubscription? completionSub;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {

          final mm = isPlaying
              ? (currentPosition.inMinutes).toString()
              : (_recordingDuration.inMinutes).toString();
          final ss = isPlaying
              ? (currentPosition.inSeconds % 60).toString().padLeft(2, '0')
              : (_recordingDuration.inSeconds % 60).toString().padLeft(2, '0');

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tiêu đề
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Xem trước ghi âm",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "$mm:$ss", // THỜI GIAN ĐỘNG
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Waveform + Play button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Play/Pause button
                      GestureDetector(
                        onTap: () async {
                          if (_pausedRecordingPath != null) {
                            if (isPlaying) {
                              // Pause
                              await _audioPlayer.pause();
                              playbackTimer?.cancel();
                              setSheetState(() {
                                isPlaying = false;
                              });
                            } else {
                              // Play
                              await _audioPlayer.play(DeviceFileSource(_pausedRecordingPath!));

                              // Reset position
                              currentPosition = Duration.zero;

                              // Bắt đầu animation
                              playbackProgress = 0;
                              playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
                                setSheetState(() {
                                  playbackProgress++;
                                  if (playbackProgress >= _waveformBarsCount) {
                                    playbackProgress = 0; // Loop lại
                                  }

                                  // Update thời gian
                                  currentPosition = Duration(milliseconds: currentPosition.inMilliseconds + 100);
                                });
                              });


                              completionSub?.cancel();
                              completionSub = _audioPlayer.onPlayerComplete.listen((_) {
                                playbackTimer?.cancel();
                                setSheetState(() {
                                  isPlaying = false;
                                  playbackProgress = 0;
                                  currentPosition = Duration.zero;
                                });
                              });

                              setSheetState(() {
                                isPlaying = true;
                              });
                            }
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),


                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _waveformBarsCount.clamp(0, 35),
                                  (index) {
                                final baseHeight = 24.0;
                                final variation = ((index * 3) % 4) * 4.0;
                                final height = baseHeight + variation;

                                // Highlight thanh đang phát
                                final isActive = isPlaying && index <= playbackProgress;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 3,
                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.primary
                                        : AppColors.primary.withAlpha((0.3 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                  height: height,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons (giữ nguyên)
                Row(
                  children: [
                    // Xóa
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          playbackTimer?.cancel();
                          completionSub?.cancel();
                          _audioPlayer.stop();
                          setState(() {
                            _recordingState = RecordingState.idle;
                            _pausedRecordingPath = null;
                            _recordingDuration = Duration.zero;
                            _waveformBarsCount = 0;
                          });
                          Get.back();
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Ghi lại
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          playbackTimer?.cancel();
                          completionSub?.cancel();
                          _audioPlayer.stop();
                          Get.back();
                          setState(() {
                            _recordingState = RecordingState.idle;
                            _recordingDuration = Duration.zero;
                            _waveformBarsCount = 0;
                          });
                          _startRecording();
                        },
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        label: const Text('Ghi lại', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Gửi
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          playbackTimer?.cancel();
                          completionSub?.cancel();
                          _audioPlayer.stop();
                          Get.back();
                          _sendVoiceMessage();
                        },
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        label: const Text('Gửi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
      isDismissible: false,
      enableDrag: true,
    ).then((_) {
      playbackTimer?.cancel();
      completionSub?.cancel();
      _audioPlayer.stop();
    });
  }

  Future<void> _sendVoiceMessage() async {
    if (_isSendingVoice) return;
    _isSendingVoice = true;
    if (_pausedRecordingPath == null || _sessionId == null) {
      _isSendingVoice = false;
      return;
    }

    final file = File(_pausedRecordingPath!);
    if (!await file.exists() || await file.length() <= 100) {
      _isSendingVoice = false;
      return;
    }

    final seconds = _recordingDuration.inSeconds;

    // Copy file sang thư mục persistent để giữ lại cho việc phát lại
    final dir = await getApplicationDocumentsDirectory();
    final persistentPath = '${dir.path}/user_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
    await file.copy(persistentPath);

    // 1) Hiển thị bubble voice của user với file persistent
    final voiceMsg = ChatMessage(
      text: '',
      isUser: true,
      timestamp: DateTime.now(),
      isVoice: true,
      audioUrl: persistentPath,
      duration: seconds,
      transcript: null,
    );
    _addMessage(voiceMsg);

    setState(() => _isTyping = true);

    // NEW: chuẩn bị chờ AI từ hub
    _awaitingVoiceAi = true;
    _voiceAiReceived = false;

    try {
      // 2) Upload HTTP để hệ thống nhận voice (đồng thời backend sẽ bắn hub)
      final resp = await _topicViewModel.sendVoiceMessage(
        sessionId: _sessionId!,
        audioFilePath: _pausedRecordingPath!,
        audioDuration: seconds,
        transcript: null,
      );
      print('[VOICE][HTTP] resp: $resp');

      final transcript = resp?['data']?['transcript'];
      final aiResponse = resp?['data']?['aiResponse'];
      final synonymSuggestions = aiResponse?['synonymSuggestions'];

      // Cập nhật user voice message với transcript + synonymSuggestions
      final idx = _messages.lastIndexWhere((m) => m.isUser && m.isVoice && m.audioUrl == persistentPath);
      if (idx != -1) {
        setState(() {
          _messages[idx] = ChatMessage(
            text: _messages[idx].text,
            isUser: true,
            timestamp: _messages[idx].timestamp,
            isVoice: true,
            audioUrl: persistentPath,
            duration: seconds,
            transcript: transcript?.toString(),
            synonymSuggestions: synonymSuggestions,
          );
        });
        if (synonymSuggestions != null) {
          print('[VOICE][HTTP] Updated voice message with synonymSuggestions');
        }
      }

      // Fallback: chỉ thêm AI từ HTTP nếu hub KHÔNG gửi
      if (!_voiceAiReceived && aiResponse != null) {
        final content = aiResponse['messageContent'] ?? '';
        final ts = DateTime.tryParse(aiResponse['sentAt'] ?? '') ?? DateTime.now();
        setState(() => _isTyping = false);
        _addMessage(ChatMessage(
          text: content,
          isUser: false,
          timestamp: ts,
          isVoice: false,
          audioUrl: null,
          duration: null,
          synonymSuggestions: null,
        ));
        print('[VOICE][HTTP] Added AI response (fallback) because hub not received');
      } else {
        setState(() => _isTyping = false);
        if (_voiceAiReceived) print('[VOICE] Skipped HTTP AI response (already from hub)');
      }
    } catch (e) {
      print('[VOICE][HTTP] upload error: $e');
      setState(() => _isTyping = false);
      Get.snackbar("Lỗi", "Không gửi được voice: $e");
    } finally {
      _awaitingVoiceAi = false;
      _voiceAiReceived = false;
      _aiResponseTimeout?.cancel();
      _aiResponseTimeout = null;
      _isSendingVoice = false;
    }

    // Reset trạng thái ghi âm, nhưng giữ file persistent cho message
    setState(() {
      _recordingState = RecordingState.idle;
      _pausedRecordingPath = null; // Có thể xóa file gốc sau khi copy
    });

    try {
      await file.delete();
    } catch (e) {
      print('[VOICE] Failed to delete temp file: $e');
    }
  }

  Widget _buildRecordingOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recording indicator với dot đỏ nhấp nháy
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                    onEnd: () {
                      if (mounted && _recordingState == RecordingState.recording) {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${_recordingDuration.inMinutes}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),],
              ),

              const SizedBox(height: 20),

              // Waveform xuất hiện dần từ trái sang phải như Facebook
              SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    35,
                        (index) {
                      // Chỉ hiển thị thanh nếu đã đến lượt nó
                      if (index >= _waveformBarsCount) {
                        return const SizedBox(width: 4.5); // Khoảng trống cho thanh chưa xuất hiện
                      }

                      // Chiều cao dao động nhẹ
                      final baseHeight = 30.0;
                      final variation = ((index * 3 + _recordingDuration.inSeconds * 2) % 4) * 3.0;
                      final targetHeight = baseHeight + variation;

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: targetHeight), // Bắt đầu từ 0
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Container(
                            width: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                            height: value,
                          );
                        },
                        onEnd: () {
                          if (mounted && _recordingState == RecordingState.recording) {
                            setState(() {});
                          }
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Stop button
              GestureDetector(
                onTap: _pauseRecording,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withAlpha((0.3 * 255).toInt()),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                'Nhấn để dừng ghi âm',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSynonymSuggestions(Map<String, dynamic> suggestions) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Gợi ý câu đồng nghĩa',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha((0.1 * 255).toInt()),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 24,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._buildSynonymSuggestionList(suggestions),
            ],
          ),
        ),
      ),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
    );
  }

  List<Widget> _buildSynonymSuggestionList(Map<String, dynamic> suggestions) {
    final List<Widget> widgets = [];

    // Hiển thị thông tin header nếu có
    if (suggestions['originalMessage'] != null) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha((0.08 * 255).toInt()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withAlpha((0.2 * 255).toInt())),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Câu gốc của bạn:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
              const SizedBox(height: 4),
              Text(suggestions['originalMessage'], style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
              if (suggestions['currentLevel'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('Level hiện tại: ${suggestions['currentLevel']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Lấy danh sách alternatives (ưu tiên alternatives, fallback sang items)
    final List<dynamic>? alternatives = suggestions['alternatives'] ?? suggestions['items'];

    if (alternatives != null && alternatives.isNotEmpty) {
      for (final item in alternatives) {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha((0.08 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withAlpha((0.2 * 255).toInt())),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['level'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Level: ${item['level']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12)),
                  ),
                if (item['alternativeText'] != null || item['sentence'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      item['alternativeText'] ?? item['sentence'] ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                if (item['difference'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Khác biệt: ${item['difference']}',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (item['exampleUsage'] != null || item['example'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Ví dụ: ${item['exampleUsage'] ?? item['example']}',
                            style: const TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    } else {
      widgets.add(const Text('Không có gợi ý đồng nghĩa.'));
    }

    // Hiển thị explanation nếu có
    if (suggestions['explanation'] != null) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha((0.08 * 255).toInt()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withAlpha((0.2 * 255).toInt())),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestions['explanation'],
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isVoice;
  final String? audioUrl;
  final int? duration;
  final String? transcript;
  final Map<String, dynamic>? synonymSuggestions;
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isVoice = false,
    this.audioUrl,
    this.duration,
    this.transcript,
    this.synonymSuggestions,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ChatMessage &&
              runtimeType == other.runtimeType &&
              text == other.text &&
              isUser == other.isUser &&
              timestamp == other.timestamp;

  @override
  int get hashCode => text.hashCode ^ isUser.hashCode ^ timestamp.hashCode;
}
