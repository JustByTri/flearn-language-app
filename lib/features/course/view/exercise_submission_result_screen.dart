import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/colors.dart';
import '../model/exercise_submission_detail.dart';

class ExerciseSubmissionResultScreen extends StatelessWidget {
  final ExerciseSubmissionDetail detail;
  const ExerciseSubmissionResultScreen({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    // Parse aiFeedback
    Map<String, dynamic>? aiFeedback;
    try {
      aiFeedback = json.decode(detail.aiFeedback ?? '{}');
    } catch (_) {}

    final scores = aiFeedback?['scores'] as Map<String, dynamic>? ?? {};
    final transcript = aiFeedback?['transcript']?.toString() ?? '';
    final feedbackList = <Map<String, dynamic>>[];
    try {
      final feedbackRaw = aiFeedback?['feedback'];
      if (feedbackRaw is String) {
        feedbackList.addAll(List<Map<String, dynamic>>.from(json.decode(feedbackRaw)));
      } else if (feedbackRaw is List) {
        feedbackList.addAll(List<Map<String, dynamic>>.from(feedbackRaw));
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Màu nền nhẹ
      appBar: AppBar(
        title: const Text('Kết quả nộp bài', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Tiêu đề bài tập
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.exerciseTitle ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text(detail.exerciseDescription ?? '-', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Thông tin cơ bản
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _kv('Trạng thái', detail.status ?? '-', Icons.info),
                    _kv('AI Score', (detail.aiScore ?? 0).toString(), Icons.star),
                    _kv('Final Score', detail.finalScore?.toString() ?? '-', Icons.check_circle),
                    _kv('Đỗ', (detail.isPassed == true) ? 'Yes' : 'No', Icons.thumb_up),
                    _kv('Submitted at', detail.submittedAt ?? '-', Icons.access_time),
                    if ((detail.audioUrl ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.volume_up, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text('Audio:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(detail.audioUrl!, style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: AppColors.primary),
                            onPressed: () async {
                              final player = AudioPlayer();
                              try {
                                if (player.state == PlayerState.playing) {
                                  await player.stop();
                                  Get.snackbar('Audio', 'Đã dừng phát');
                                } else {
                                  await player.play(UrlSource(detail.audioUrl!));
                                  Get.snackbar('Audio', 'Đang phát audio');
                                }
                              } catch (e) {
                                Get.snackbar('Lỗi', 'Không thể phát audio: $e');
                              } finally {
                                player.dispose();
                              }
                            },
                            tooltip: 'Phát audio',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Transcript
            if (transcript.isNotEmpty) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.text_fields, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Transcript: $transcript', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Điểm thành phần từ aiFeedback
            if (scores.isNotEmpty) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Điểm thành phần:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: scores.entries.map((e) => Chip(
                          label: Text('${e.key}: ${e.value}'),
                          backgroundColor: Colors.grey.shade200,
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Phân tích phát âm
            if (feedbackList.isNotEmpty) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  title: const Text('Phân tích phát âm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text('Chi tiết độ chính xác của từng âm tiết (${feedbackList.length} âm)'),
                  children: [
                    const SizedBox(height: 8),
                    if (transcript.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Transcript gốc: $transcript', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Chi tiết âm tiết (sát nhau, màu sắc theo độ chính xác):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 2,
                        runSpacing: 4,
                        children: feedbackList.map((f) {
                          final phoneme = f['Phoneme'] ?? '';
                          final acc = f['Accuracy'] ?? 0;
                          final color = f['Color'] ?? '';
                          Color bgColor = Colors.grey.shade200;
                          Color textColor = Colors.black;
                          if (color == 'green') {
                            bgColor = Colors.green.shade100;
                            textColor = Colors.green.shade800;
                          } else if (color == 'yellow') {
                            bgColor = Colors.yellow.shade100;
                            textColor = Colors.orange.shade800;
                          } else if (color == 'red') {
                            bgColor = Colors.red.shade100;
                            textColor = Colors.red.shade800;
                          }
                          return Tooltip(
                            message: 'Âm tiết "$phoneme": Độ chính xác $acc%',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                phoneme,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          SizedBox(width: 120, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}