import 'package:flutter/material.dart';

class ChatHistoryScreen extends StatelessWidget {
  final List messages;
  const ChatHistoryScreen({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
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
          return ListTile(
            leading: Icon(msg.isUser ? Icons.person : Icons.smart_toy),
            title: Text(msg.text),
            subtitle: Text(msg.timestamp.toString()),
            tileColor: msg.isUser ? Colors.blue[50] : Colors.orange[50],
          );
        },
      ),
    );
  }
}