import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../topic/model/topic.dart';

class ChatScreen extends StatefulWidget {
  final TopicModel topic;

  const ChatScreen({super.key, required this.topic});

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

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Welcome message from AI
    _addMessage(ChatMessage(
      text: "Xin chào! Tôi là AI assistant của bạn. Hôm nay chúng ta sẽ trò chuyện về chủ đề: ${widget.topic.topicName}. ${widget.topic.topicDescription}",
      isUser: false,
      timestamp: DateTime.now(),
    ));
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
        if (mounted) {
          await _sendFileToApi(file);
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

  Future<void> _sendFileToApi(File file) async {
    final uri = Uri.parse('https://xbensieve-pronunciation-assessment-api.hf.space/api/transcribe');
    final request = http.MultipartRequest('POST', uri)
      ..fields['lang'] = 'en' // Default to English; adjust based on topic if needed
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('audio', 'wav'),
      ));

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (mounted) {
          // Add transcribed text as user message
          _addMessage(ChatMessage(
            text: respStr,
            isUser: true,
            timestamp: DateTime.now(),
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã nhận diện: $respStr')),
          );
          _simulateTyping(); // Trigger AI response
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi gửi file: $respStr')),
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi gửi file đến API: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi file đến API: $e')),
        );
      }
    }
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _messageController.clear();
    _simulateTyping();
  }

  void _simulateTyping() {
    setState(() => _isTyping = true);

    // Simulate AI response delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isTyping = false);
        _generateAIResponse();
      }
    });
  }

  void _generateAIResponse() {
    final responses = _getTopicResponses();
    final randomResponse = responses[DateTime.now().millisecond % responses.length];

    _addMessage(ChatMessage(
      text: randomResponse,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  List<String> _getTopicResponses() {
    switch (widget.topic.topicName.toLowerCase()) {
      case 'conversation':
        return [
          "Tuyệt vời! Hãy thử nói về sở thích của bạn. What do you like to do in your free time?",
          "Rất hay! Bạn có thể kể về một ngày bình thường của mình không?",
          "Interesting! Could you tell me about your favorite food?",
          "Great! What's your opinion about social media these days?",
        ];
      case 'daily meeting':
        return [
          "Good point! In meetings, we often start with 'Good morning everyone'. How would you introduce yourself?",
          "Excellent! Can you practice saying 'I'd like to share an update on...'?",
          "Well done! How about we practice asking questions like 'Could you clarify that point?'",
          "Perfect! Try expressing agreement: 'I completely agree with your suggestion.'",
        ];
      case 'grammar':
        return [
          "Tốt lắm! Hãy thử tạo một câu sử dụng thì hiện tại hoàn thành.",
          "Excellent! Can you make a sentence using 'would rather'?",
          "Great job! Try using conditional sentences: 'If I were you...'",
          "Well done! Practice with passive voice: 'The book was written by...'",
        ];
      case 'pronunciation':
        return [
          "Tuyệt vời! Hãy thử phát âm từ 'pronunciation' - /prəˌnʌnsiˈeɪʃən/",
          "Great! Practice the 'th' sound: 'think', 'thank', 'thought'",
          "Excellent! Try these words: 'world', 'work', 'word' - notice the 'w' and 'r' sounds",
          "Perfect! Let's work on vowel sounds: 'bit' vs 'beat', 'sit' vs 'seat'",
        ];
      case 'vocabulary':
        return [
          "Tuyệt vời! Từ 'serendipity' có nghĩa là gì? Hãy thử sử dụng nó trong câu.",
          "Great! Can you think of synonyms for 'beautiful'? Try: gorgeous, stunning, magnificent",
          "Excellent! What's the difference between 'affect' and 'effect'?",
          "Perfect! Let's learn phrasal verbs: 'give up', 'put off', 'look forward to'",
        ];
      default:
        return [
          "Thật thú vị! Bạn có thể chia sẻ thêm về điều đó không?",
          "Tuyệt vời! Hãy tiếp tục thực hành nhé.",
          "Rất hay! Tôi hiểu quan điểm của bạn.",
          "Excellent! Keep practicing and you'll improve quickly!",
        ];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_isRecording) _stopRecording(); // Stop recording when tapping outside
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
                widget.topic.topicName,
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          elevation: 0,
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
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              if (_isTyping) _buildTypingIndicator(),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(false),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.primary : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
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