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

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _topicViewModel = Get.find<TopicViewModel>();

  bool _isRecording = false;
  bool _isTyping = false;
  bool _isEnding = false; // Trạng thái chờ khi kết thúc
  String? _sessionId;
  ConversationSessionModel? _sessionModel;

  final Set<ChatMessage> _translatedMessages = {};
  bool _isScenarioTranslated = false;
  bool _isRoleTranslated = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
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

    _topicViewModel.initSignalR();
    _topicViewModel.aiMessageStream.listen((msg) {
      if (msg['sender'] == 2 && mounted) {
        setState(() => _isTyping = false);
        _addMessage(ChatMessage(
          text: msg['messageContent'] ?? '',
          isUser: false,
          timestamp: DateTime.tryParse(msg['sentAt'] ?? '') ?? DateTime.now(),
        ));
      }
    });
    if (_sessionId != null) {
      _topicViewModel.joinConversationRoom(_sessionId!);
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  void _addMessage(ChatMessage message) {
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
      final response = await _topicViewModel.sendConversationMessage(
        sessionId: _sessionId!,
        messageContent: text,
        messageType: 1,
      );
      setState(() => _isTyping = false);

      if (response != null && response['success'] == true && response['data'] != null) {
        final aiMsg = response['data']['messageContent'] ?? '';
        if (aiMsg.isNotEmpty) {
           _addMessage(ChatMessage(text: aiMsg.trim(), isUser: false, timestamp: DateTime.now()));
        }
      } else {
         _addMessage(ChatMessage(text: "AI không trả lời. Vui lòng thử lại.", isUser: false, timestamp: DateTime.now()));
      }
    } catch (e) {
      setState(() => _isTyping = false);
      Get.snackbar("Lỗi", "Không thể gửi tin nhắn: $e");
    }
  }

  Future<void> _handleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
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
      setState(() => _isRecording = true);
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể bắt đầu ghi âm: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        final file = File(path);
        if (await file.exists() && await file.length() > 100) {
          setState(() => _isTyping = true);

          final response = await _topicViewModel.sendVoiceMessage(
            sessionId: _sessionId!,
            audioFilePath: path,
            audioDuration: 0,
          );

          if (response != null && response['success'] == true && response['data'] != null) {
            final audioUrl = response['data']['audioUrl'];
            await _topicViewModel.sendVoiceMessageSignalR(
              sessionId: _sessionId!,
              audioUrl: audioUrl,
              audioDuration: 0,
            );
          } else {
            setState(() => _isTyping = false);
            Get.snackbar("Lỗi", "Không thể tải lên tin nhắn thoại.");
          }
        } else {
          Get.snackbar("Lỗi", "File ghi âm quá ngắn hoặc không hợp lệ.");
        }
      }
    } catch (e) {
      setState(() => _isTyping = false);
      Get.snackbar("Lỗi", "Không thể gửi tin nhắn thoại: $e");
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
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
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

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          _buildHeader(),
          _buildChatBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.back, color: Colors.white, size: 28),
                  onPressed: () => Get.back(),
                ),
                TextButton(
                  onPressed: _confirmEndConversation,
                  child: const Text(
                    "Kết thúc",
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   GestureDetector(
                     onTap: () => setState(() => _isScenarioTranslated = !_isScenarioTranslated),
                     child: Text.rich(TextSpan(children: [
                       const TextSpan(text: "Kịch bản: ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       TextSpan(text: _getTranslatedText(_sessionModel?.scenarioDescription ?? '...', _isScenarioTranslated),
                         style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.normal))
                     ]))
                   ),
                  const SizedBox(height: 8),
                  GestureDetector(
                     onTap: () => setState(() => _isRoleTranslated = !_isRoleTranslated),
                     child: Text.rich(TextSpan(children: [
                       TextSpan(text: "Vai của bạn: ", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15, fontWeight: FontWeight.bold)),
                       TextSpan(text: _getTranslatedText(_sessionModel?.characterRole ?? '...', _isRoleTranslated),
                         style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15))
                     ]))
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBody() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Column(
            children: [
              if (_sessionModel?.tasks != null && _sessionModel!.tasks.isNotEmpty)
                _buildTasks(),
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
      ),
    );
  }

  Widget _buildTasks(){
    List<String> taskContents = [];
    if (_sessionModel?.tasks != null) {
      for (var task in _sessionModel!.tasks) {
        if (task is Map<String, dynamic> && task.containsKey('taskDescription') && task['taskDescription'] is String) {
          taskContents.add(task['taskDescription']);
        }
      }
    }

    if (taskContents.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Nhiệm vụ của bạn:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
          const SizedBox(height: 8),
          ...taskContents.map((taskContent) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text("- $taskContent", style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
          ))
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
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

    final displayText = _getTranslatedText(message.text, isTranslated);
    final words = displayText.split(' ');

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: Get.width * 0.75),
          decoration: BoxDecoration(color: color, borderRadius: radius),
          child: RichText(
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
          child: Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
      ],
    );
  }


  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(width: 50, height: 20, child: CupertinoActivityIndicator(radius: 8)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(offset: const Offset(0, -2), blurRadius: 5, color: Colors.grey.withOpacity(0.08))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(icon: const Icon(CupertinoIcons.smiley), color: Colors.grey.shade600, onPressed: () {}),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(_isRecording ? CupertinoIcons.stop_fill : CupertinoIcons.mic, color: _isRecording ? Colors.red : Colors.grey.shade600),
              onPressed: _handleRecording,
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.paperplane_fill, color: AppColors.primary),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});

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
