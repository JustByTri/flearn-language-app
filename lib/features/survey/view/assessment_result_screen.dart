import 'package:flutter/material.dart';
import '../../auth/view/home_screen.dart';

class AssessmentResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  const AssessmentResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final voiceResult = result['data']['voiceResult'] ?? result['data']['result'];
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả đánh giá')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trình độ: ${voiceResult['determinedLevel']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Độ tin cậy: ${voiceResult['levelConfidence']}%'),
              Text('Hoàn thành: ${voiceResult['assessmentCompleteness']}'),
              Text('Điểm tổng thể: ${voiceResult['overallScore']}'),
              Text('Phát âm: ${voiceResult['pronunciationScore']}'),
              Text('Độ trôi chảy: ${voiceResult['fluencyScore']}'),
              Text('Ngữ pháp: ${voiceResult['grammarScore']}'),
              Text('Từ vựng: ${voiceResult['vocabularyScore']}'),
              const SizedBox(height: 16),
              Text('Nhận xét:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(voiceResult['detailedFeedback'] ?? ''),
              const SizedBox(height: 16),
              if (voiceResult['keyStrengths'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thế mạnh:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List.generate(
                      (voiceResult['keyStrengths'] as List).length,
                          (i) => Text('- ${voiceResult['keyStrengths'][i]}'),
                    ),
                  ],
                ),
              if (voiceResult['improvementAreas'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cần cải thiện:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List.generate(
                      (voiceResult['improvementAreas'] as List).length,
                          (i) => Text('- ${voiceResult['improvementAreas'][i]}'),
                    ),
                  ],
                ),
              if (voiceResult['nextLevelRequirements'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Yêu cầu để lên trình tiếp theo: ${voiceResult['nextLevelRequirements']}'),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                          (route) => false,
                    );
                  },
                  child: const Text('Hoàn thành'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}