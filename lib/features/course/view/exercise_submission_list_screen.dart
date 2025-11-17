import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';  // Thêm import
import '../../../core/constants/colors.dart';
import '../data/course_service.dart';
import '../model/all_exercise_submit.dart';

class ExerciseSubmissionListScreen extends StatefulWidget {
  final String exerciseId;
  final String exerciseTitle;
  const ExerciseSubmissionListScreen({super.key, required this.exerciseId, required this.exerciseTitle});

  @override
  State<ExerciseSubmissionListScreen> createState() => _ExerciseSubmissionListScreenState();
}

class _ExerciseSubmissionListScreenState extends State<ExerciseSubmissionListScreen> {
  bool _loading = true;
  List<ExerciseSubmission> _submissions = [];
  String? _error;
  final AudioPlayer _audioPlayer = AudioPlayer();  // Thêm AudioPlayer

  @override
  void dispose() {
    _audioPlayer.dispose();  // Dọn dẹp khi dispose
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await CourseService().getExerciseSubmissions(exerciseId: widget.exerciseId);
      setState(() { _submissions = list; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Màu nền nhẹ
      appBar: AppBar(
        title: Text('Xem điểm: ${widget.exerciseTitle}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? Center(child: Text('Lỗi: $_error', style: const TextStyle(color: Colors.red)))
          : _submissions.isEmpty
          ? const Center(child: Text('Chưa có bài nộp nào', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _submissions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final sub = _submissions[i];
          return _buildSubmissionCard(sub);
        },
      ),
    );
  }

  Widget _buildSubmissionCard(ExerciseSubmission sub) {
    // Giải mã aiFeedback
    Map<String, dynamic>? aiFeedback;
    try {
      aiFeedback = json.decode(sub.aiFeedback);
    } catch (_) {}

    final scores = aiFeedback?['scores'] as Map<String, dynamic>? ?? {};
    final overall = aiFeedback?['overall']?.toString() ?? sub.aiScore.toString();
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(  // Thay Column bằng ListView để tránh overflow
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Thời gian nộp
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Lần nộp: ${sub.submittedAt}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const Divider(height: 16, color: Colors.grey),
            // Điểm số
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('Điểm AI: $overall', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.blue,
                  avatar: const Icon(Icons.star, color: Colors.white, size: 16),
                ),
                Chip(
                  label: Text('Điểm cuối: ${sub.finalScore}', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.green,
                  avatar: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                ),
                if (sub.isPassed)
                  Chip(
                    label: const Text('Đạt', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green.shade600,
                    avatar: const Icon(Icons.thumb_up, color: Colors.white, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Transcript
            if (transcript.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.text_fields, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Transcript: $transcript', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Audio
            if (sub.audioUrl.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.volume_up, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Audio:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(sub.audioUrl, style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow, color: AppColors.primary),
                    onPressed: () async {
                      try {
                        if (_audioPlayer.state == PlayerState.playing) {
                          await _audioPlayer.stop();
                          Get.snackbar('Audio', 'Đã dừng phát');
                        } else {
                          await _audioPlayer.play(UrlSource(sub.audioUrl));
                          Get.snackbar('Audio', 'Đang phát audio');
                        }
                      } catch (e) {
                        Get.snackbar('Lỗi', 'Không thể phát audio: $e');
                      }
                    },
                    tooltip: 'Phát audio',
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Điểm thành phần
            if (scores.isNotEmpty) ...[
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
              const SizedBox(height: 12),
            ],
            // Phân tích phát âm - Thay GridView bằng Wrap để tránh overflow
            if (feedbackList.isNotEmpty) ...[
              ExpansionTile(
                title: const Text('Phân tích phát âm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                subtitle: Text('Chi tiết độ chính xác của từng âm tiết (${feedbackList.length} âm)'),
                children: [
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            phoneme,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Nhận xét giáo viên
            if (sub.teacherFeedback.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment, size: 20, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Nhận xét giáo viên: ${sub.teacherFeedback}', style: const TextStyle(color: Colors.deepOrange, fontSize: 14)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}