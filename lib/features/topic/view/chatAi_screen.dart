import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../topic/model/topic.dart';
import '../viewmodel/topic_viewmodel.dart';
import 'conversation_result_screen.dart';
import 'chat_history_screen.dart';

class ChatScreen extends StatefulWidget {
  final TopicModel topic;
  final String? difficultyLevel;
  final Map<String, dynamic>? conversationData;

  const ChatScreen({
    super.key,
    required this.topic,
    this.difficultyLevel,
    this.conversationData,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isTyping = false;
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedFilePath;
  String? _sessionId;
  late TopicViewModel _topicViewModel;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<int> _translatedIndexes = {};

  @override
  void initState() {
    super.initState();
    _topicViewModel = Get.find<TopicViewModel>();
    _requestPermissions();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();


    if (widget.conversationData != null) {
      _sessionId = widget.conversationData!['sessionId'];
      final List<dynamic> msgs = widget.conversationData!['messages'] ?? [];
      for (final msg in msgs) {
        _addMessage(ChatMessage(
          text: msg['messageContent'] ?? '',
          isUser: msg['sender'] == 1,
          timestamp: DateTime.tryParse(msg['sentAt'] ?? '') ?? DateTime.now(),
        ));
      }
    } else {
      _startConversation();
    }
  }

  Future<void> _startConversation() async {
    setState(() => _isTyping = true);
    final languageId = GetStorage().read('selectedLanguageId');
    final difficultyLevel = widget.difficultyLevel ?? "A1";
    final conversationData = await _topicViewModel.startConversation(
      languageId: languageId,
      topicId: widget.topic.topicId,
      difficultyLevel: difficultyLevel,
    );
    setState(() => _isTyping = false);
    if (conversationData != null) {
      _sessionId = conversationData['sessionId'];
      final List<dynamic> msgs = conversationData['messages'] ?? [];
      for (final msg in msgs) {
        _addMessage(ChatMessage(
          text: msg['messageContent'] ?? '',
          isUser: msg['sender'] == 1,
          timestamp: DateTime.tryParse(msg['sentAt'] ?? '') ?? DateTime.now(),
        ));
      }
    } else {
      _addMessage(ChatMessage(
        text: "Không thể bắt đầu cuộc trò chuyện với AI.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();
    if (microphoneStatus.isDenied || microphoneStatus.isPermanentlyDenied ||
        storageStatus.isDenied || storageStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền truy cập micro hoặc bộ nhớ')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await Permission.microphone.isGranted) {
        await _requestPermissions();
        if (!await Permission.microphone.isGranted) return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/chat_audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: filePath);

      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordedFilePath = filePath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang ghi âm...')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi bắt đầu ghi âm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi bắt đầu ghi âm: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
        });
      }
      if (path != null && File(path).existsSync()) {
        final file = File(path);
        if (file.lengthSync() == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File ghi âm rỗng!')),
            );
          }
          return;
        }

        setState(() => _isTyping = true);
        final response = await _topicViewModel.sendVoiceMessage(
          sessionId: _sessionId!,
          audioFilePath: path,
          audioDuration: 0,
        );
        setState(() => _isTyping = false);

        if (response != null && response['success'] == true && response['data'] != null) {
          final aiMsg = response['data']['aiResponse'];
          if (aiMsg != null && aiMsg['sender'] == 2) {
            _addMessage(ChatMessage(
              text: aiMsg['messageContent'] ?? '',
              isUser: false,
              timestamp: DateTime.tryParse(aiMsg['sentAt'] ?? '') ?? DateTime.now(),
            ));
          }
        } else {
          _addMessage(ChatMessage(
            text: "AI không trả lời voice. Vui lòng thử lại.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: File không được lưu')),
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi dừng ghi âm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi dừng ghi âm: $e')),
        );
      }
    }
  }

  Future<void> _playRecordedAudio() async {
    if (_recordedFilePath == null || !File(_recordedFilePath!).existsSync()) return;
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
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

    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _messageController.clear();

    setState(() => _isTyping = true);

    final response = await _topicViewModel.sendConversationMessage(
      sessionId: _sessionId!,
      messageContent: text,
      messageType: 1,
    );
    print('AI response: $response');

    setState(() => _isTyping = false);


    if (response != null && response['success'] == true && response['data'] != null) {
      final msg = response['data'];
      if (msg['sender'] == 2) {
        _addMessage(ChatMessage(
          text: msg['messageContent'] ?? '',
          isUser: false,
          timestamp: DateTime.tryParse(msg['sentAt'] ?? '') ?? DateTime.now(),
        ));
      }
    } else {
      _addMessage(ChatMessage(
        text: "AI không trả lời. Vui lòng thử lại.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _endConversation() async {
    if (_sessionId == null) return;
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/conversation/$_sessionId/end');
    try {
      final response = await http.post(
        url,
        headers: {
          "accept": "*/*",
          "Authorization": "Bearer $accessToken",
        },
      );
      if (response.statusCode == 200) {
        final json = response.body;
        final Map<String, dynamic> result = jsonDecode(json);
        if (result['success'] == true && result['data'] != null) {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ConversationResultScreen(resultData: result['data']),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kết thúc thất bại: ${result['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kết thúc thất bại: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_isRecording) _stopRecording();
      },
      child: AppScaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textLight),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "AI Chat",
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.topic.name, // Sửa lại ở đây
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.history, color: Colors.white),
              tooltip: "Lịch sử chat",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatHistoryScreen(messages: _messages),
                  ),
                );
              },
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message, index);
                  },
                ),
              ),
              if (_isTyping) _buildTypingIndicator(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _endConversation,
                  icon: const Icon(Icons.stop_circle, color: Colors.white),
                  label: const Text("Kết thúc cuộc trò chuyện"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, [int? index]) {
    String en = message.text;
    String? vi;
    if (!message.isUser && message.text.contains('|')) {
      final parts = message.text.split('|');
      en = parts[0].trim();
      vi = parts.length > 1 ? parts[1].trim() : null;
    }

    final isTranslated = index != null && _translatedIndexes.contains(index);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(false),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser ? AppColors.primary : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (!message.isUser && vi != null && isTranslated) ? vi! : en,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (!message.isUser && vi != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 28),
                    ),
                    onPressed: () {
                      if (index != null) {
                        setState(() {
                          if (_translatedIndexes.contains(index)) {
                            _translatedIndexes.remove(index);
                          } else {
                            _translatedIndexes.add(index);
                          }
                        });
                      }
                    },
                    child: Text(
                      isTranslated ? 'Xem bản gốc' : 'Dịch',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? AppColors.primary.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 16,
        color: isUser ? AppColors.primary : Colors.orange,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildAvatar(false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final value = (_animationController.value + index * 0.3) % 1.0;
        return Transform.translate(
          offset: Offset(0, -10 * (value < 0.5 ? value * 2 : (1 - value) * 2)),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Nhập tin nhắn hoặc nói...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
              onPressed: _isRecording ? _stopRecording : _startRecording,
            ),
          ),
          if (_recordedFilePath != null && !_isRecording) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                tooltip: 'Nghe lại ghi âm',
                onPressed: _playRecordedAudio,
              ),
            ),
          ],
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}