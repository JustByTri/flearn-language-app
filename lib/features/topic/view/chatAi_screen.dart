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

  @override
  void initState() {
    super.initState();
    _initializeChat();
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
      setState(() => _isTyping = false);

      final content = aiMsg['content'] ?? aiMsg['messageContent'] ?? '';
      final ts = DateTime.tryParse(aiMsg['timestamp'] ?? aiMsg['sentAt'] ?? '') ?? DateTime.now();

      // Chỉ tạo ChatMessage dạng text cho AI
      _addMessage(ChatMessage(
        text: content,
        isUser: false,
        timestamp: ts,
        isVoice: false,
        audioUrl: null,
        duration: null,
      ));
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
      await _topicViewModel.sendConversationMessageSignalR(
        sessionId: _sessionId!,
        messageContent: text,
        messageType: "Text", // Đảm bảo đúng enum/chuỗi backend yêu cầu
      );
      // Không set _isTyping = false ở đây. Sẽ tắt khi nhận AIMessageReceived hoặc khi catch lỗi.
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
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    _textFocusNode.dispose();
    _recordingTimer?.cancel();
    _voicePlaybackTimer?.cancel();
    _voiceCompletionSub?.cancel();
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
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: _getTranslatedText(_sessionModel?.characterRole ?? '...', _isRoleTranslated),
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
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
    final isVoice = message.isVoice; // THÊM FIELD isVoice vào ChatMessage
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

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: Get.width * 0.75),
          decoration: BoxDecoration(color: color, borderRadius: radius),
          child: isVoice
              ? _buildVoiceMessageContent(message, textColor)
              : _buildTextMessageContent(message, isTranslated, hasTranslation, textColor),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
          child: Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
        if (!isUser && !isVoice) _buildTranslationButton(msgIndex, message),
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
                            : (isUser ? Colors.white : AppColors.primary).withOpacity(0.3),
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
                  color: (_recordingState == RecordingState.recording ? Colors.red : AppColors.primary).withOpacity(0.3),
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
                                        : AppColors.primary.withOpacity(0.3),
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
    if (_pausedRecordingPath == null || _sessionId == null) return;

    final file = File(_pausedRecordingPath!);
    if (!await file.exists() || await file.length() <= 100) return;

    final seconds = _recordingDuration.inSeconds;

    // Copy file sang thư mục persistent để giữ lại cho việc phát lại
    final dir = await getApplicationDocumentsDirectory();
    final persistentPath = '${dir.path}/user_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
    await file.copy(persistentPath); // Copy file để tránh bị xóa

    // 1) Hiển thị bubble voice của user với file persistent
    _addMessage(ChatMessage(
      text: '',
      isUser: true,
      timestamp: DateTime.now(),
      isVoice: true,
      audioUrl: persistentPath, // Dùng đường dẫn persistent
      duration: seconds,
    ));

    setState(() => _isTyping = true);

    // 2) Upload HTTP để lấy audioUrl và aiResponse
    try {
      final resp = await _topicViewModel.sendVoiceMessage(
        sessionId: _sessionId!,
        audioFilePath: _pausedRecordingPath!, // Vẫn dùng file gốc để upload
        audioDuration: seconds,
        transcript: null,
      );
      print('[VOICE][HTTP] resp: $resp');

      // Xử lý aiResponse từ response
      final aiResponse = resp?['data']?['aiResponse'];
      if (aiResponse != null) {
        final content = aiResponse['messageContent'] ?? '';
        final ts = DateTime.tryParse(aiResponse['sentAt'] ?? '') ?? DateTime.now();

        // Thêm tin nhắn AI vào UI
        _addMessage(ChatMessage(
          text: content,
          isUser: false,
          timestamp: ts,
          isVoice: false,
          audioUrl: null,
          duration: null,
        ));
      }

      // Nếu muốn gửi qua SignalR (tùy backend), bỏ comment và sửa
      // if (aiResponse != null && aiResponse['audioUrl'] != null) {
      //   await _topicViewModel.sendVoiceMessageSignalR(
      //     sessionId: _sessionId!,
      //     audioUrl: aiResponse['audioUrl'],
      //     audioDuration: seconds,
      //   );
      // }
    } catch (e) {
      print('[VOICE][HTTP] upload error: $e');
      setState(() => _isTyping = false);
      Get.snackbar("Lỗi", "Không gửi được voice: $e");
    } finally {
      // Đảm bảo tắt _isTyping nếu không có lỗi
      setState(() => _isTyping = false);
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
                  ),
                ],
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
                        color: Colors.red.withOpacity(0.3),
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
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isVoice;
  final String? audioUrl;
  final int? duration;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isVoice = false,
    this.audioUrl,
    this.duration,
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
