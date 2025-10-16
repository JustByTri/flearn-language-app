import 'package:flutter/material.dart';

class ConversationResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;
  const ConversationResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá cuộc trò chuyện'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Điểm tổng thể: ${resultData['overallScore']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Điểm lưu loát: ${resultData['fluentScore']}'),
              Text('Điểm ngữ pháp: ${resultData['grammarScore']}'),
              Text('Điểm từ vựng: ${resultData['vocabularyScore']}'),
              Text('Điểm văn hóa: ${resultData['culturalScore']}'),
              const SizedBox(height: 16),
              Text('Nhận xét của AI:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(resultData['aiFeedback'] ?? ''),
              const SizedBox(height: 12),
              Text('Điểm mạnh:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(resultData['strengths'] ?? ''),
              const SizedBox(height: 12),
              Text('Cần cải thiện:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(resultData['improvements'] ?? ''),
              const SizedBox(height: 16),
              Text('Số tin nhắn: ${resultData['totalMessages']}'),
              Text('Thời lượng (giây): ${resultData['sessionDuration']}'),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Về trang chủ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}