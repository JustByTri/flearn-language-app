import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/conversation_session.dart';

class ChatHistoryScreen extends StatelessWidget {
  // Thay đổi kiểu dữ liệu để chặt chẽ hơn
  final List<ConversationMessage> messages;
  const ChatHistoryScreen({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    // Sắp xếp tin nhắn theo thứ tự thời gian tăng dần
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chat'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          final isUser = msg.sender == 1;

          // Định dạng lại thời gian cho dễ đọc
          final formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(msg.sentAt);

          Widget title;
          Widget? subtitle;

          // --- BẮT ĐẦU THAY ĐỔI ---

          if (msg.isVoiceMessage) {
            // Nếu là tin nhắn thoại
            title = const Row(
              children: [
                Icon(Icons.mic, size: 20, color: Colors.black54),
                SizedBox(width: 8),
                Text('Tin nhắn thoại', style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            );
            // Hiển thị transcript trong subtitle nếu có
            if (msg.transcript != null && msg.transcript!.isNotEmpty) {
              subtitle = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${msg.transcript!}"', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(formattedTime),
                ],
              );
            } else {
              subtitle = Text(formattedTime);
            }
          } else {
            // Nếu là tin nhắn văn bản
            title = Text(msg.messageContent);
            subtitle = Text(formattedTime);
          }
          // --- KẾT THÚC THAY ĐỔI ---

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: Icon(isUser ? Icons.person_outline : Icons.smart_toy_outlined, color: isUser ? Colors.blue : Colors.orange),
              title: title,
              subtitle: subtitle,
              tileColor: isUser ? Colors.blue[50] : Colors.white,
              isThreeLine: msg.isVoiceMessage && msg.transcript != null && msg.transcript!.isNotEmpty, // Cho phép ListTile có 3 dòng
            ),
          );
        },
      ),
    );
  }
}