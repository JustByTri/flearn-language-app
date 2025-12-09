import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/colors.dart';
import '../model/exercise_submission_detail.dart';

class ExerciseSubmissionResultScreen extends StatefulWidget {
  final ExerciseSubmissionDetail detail;
  const ExerciseSubmissionResultScreen({super.key, required this.detail});

  @override
  State<ExerciseSubmissionResultScreen> createState() => _ExerciseSubmissionResultScreenState();
}

class _ExerciseSubmissionResultScreenState extends State<ExerciseSubmissionResultScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        if (state == PlayerState.completed) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;

    // Parse aiFeedback
    Map<String, dynamic>? aiFeedback;
    try {
      aiFeedback = json.decode(detail.aiFeedback ?? '{}');
    } catch (_) {}

    final scores = aiFeedback?['scores'] as Map<String, dynamic>? ?? {};
    final transcript = aiFeedback?['transcript']?.toString() ?? '';
    final recognizedText = aiFeedback?['recognizedText']?.toString() ?? '';
    final overall = aiFeedback?['overall']?.toString() ?? detail.aiScore.toString();

    final String aiComment = (() {
      try {
        final feedbackRaw = aiFeedback?['feedback'];
        if (feedbackRaw == null) return '';
        if (feedbackRaw is List) return '';
        if (feedbackRaw is String) {
          final trimmed = feedbackRaw.trim();
          if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
            return '';
          } else {
            return feedbackRaw;
          }
        }
        return '';
      } catch (_) {
        return '';
      }
    }());

    final feedbackList = <Map<String, dynamic>>[];
    try {
      final feedbackRaw = aiFeedback?['feedback'];
      if (feedbackRaw is List) {
        feedbackList.addAll(List<Map<String, dynamic>>.from(feedbackRaw));
      } else if (feedbackRaw is String) {
        final trimmed = feedbackRaw.trim();
        if (trimmed.startsWith('[')) {
          feedbackList.addAll(List<Map<String, dynamic>>.from(json.decode(trimmed)));
        }
      }
    } catch (_) {}

    // NEW: Check xem có điểm giáo viên không
    final hasTeacherScore = (detail.teacherScore ?? 0) > 0;

    // NEW: Check loại bài tập (nếu detail có exerciseType)
    final isRepeatAfterMe = detail.exerciseType == 'RepeatAfterMe';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Kết quả nộp bài: ${detail.exerciseTitle ?? "Bài tập"}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildSubmissionCard(
          detail,
          overall,
          scores,
          recognizedText,
          aiComment,
          feedbackList,
          transcript,
          hasTeacherScore,
          isRepeatAfterMe,
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(
      ExerciseSubmissionDetail detail,
      String overall,
      Map<String, dynamic> scores,
      String recognizedText,
      String aiComment,
      List<Map<String, dynamic>> feedbackList,
      String transcript,
      bool hasTeacherScore,
      bool isRepeatAfterMe,
      ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_turned_in, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kết quả bài nộp',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail.submittedAt ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NEW: Điểm số - Thêm điểm giáo viên nếu có
                  if (hasTeacherScore)
                  // Nếu có điểm giáo viên -> 4 cards (2 rows)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildScoreCard(
                                'Điểm AI',
                                '$overall/100',
                                Icons.smart_toy,
                                Colors.blue,
                                '30% tổng điểm', // Có thể dùng detail.aiPercent nếu có
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildScoreCard(
                                'Điểm GV',
                                '${detail.teacherScore}/100',
                                Icons.person,
                                Colors.purple,
                                '70% tổng điểm', // Có thể dùng detail.teacherPercent nếu có
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildScoreCard(
                                'Tổng điểm',
                                '${detail.finalScore?.toStringAsFixed(1) ?? 0}',
                                detail.isPassed ?? false ? Icons.check_circle : Icons.cancel,
                                detail.isPassed ?? false ? Colors.green : Colors.red,
                                detail.isPassed ?? false ? 'Đạt yêu cầu' : 'Chưa đạt',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildScoreCard(
                                'Điểm cần đạt',
                                '${detail.passScore ?? 0}',
                                Icons.flag,
                                Colors.orange,
                                'Mục tiêu',
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                  // Nếu KHÔNG có điểm giáo viên -> 2 cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreCard(
                            'Điểm AI',
                            '$overall/100',
                            detail.isPassed ?? false ? Icons.check_circle : Icons.cancel,
                            detail.isPassed ?? false ? Colors.green : Colors.red,
                            detail.isPassed ?? false ? 'Đạt yêu cầu' : 'Chưa đạt',
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildScoreCard(
                          'Điểm cần đạt',
                          '${detail.passScore ?? 0}',
                          Icons.flag,
                          Colors.orange,
                          'Mục tiêu',
                        ),
                      ],
                    ),

                  // Câu nói được nhận diện
                  if (recognizedText.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      Icons.record_voice_over,
                      'Câu nói của bạn',
                      recognizedText,
                      Colors.blue,
                    ),
                  ],

                  // Đánh giá AI
                  if (aiComment.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      Icons.psychology,
                      'Đánh giá từ AI',
                      aiComment,
                      Colors.purple,
                    ),
                  ],

                  // Transcript
                  if (transcript.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      Icons.text_snippet,
                      'Transcript',
                      transcript,
                      Colors.teal,
                    ),
                  ],

                  // Audio player
                  if (detail.audioUrl != null && detail.audioUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAudioPlayer(detail.audioUrl!),
                  ],

                  // NEW: Điểm thành phần - Lọc bỏ completeness nếu KHÔNG phải RepeatAfterMe
                  if (scores.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Điểm thành phần',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: scores.entries.where((e) {
                        // NEW: Chỉ hiển thị điểm > 0
                        final value = e.value;
                        if (value == null) return false;
                        if (value is num && value <= 0) return false;

                        // NEW: Nếu KHÔNG phải RepeatAfterMe, bỏ qua completeness
                        if (!isRepeatAfterMe && e.key.toLowerCase() == 'completeness') {
                          return false;
                        }

                        return true;
                      }).map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.primary.withOpacity(0.05)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${_translateScoreName(e.key)}: ${e.value}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Phân tích phát âm
                  if (feedbackList.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildPronunciationAnalysis(feedbackList),
                  ],

                  // NEW: Nhận xét giáo viên - LUÔN HIỂN THỊ nếu có teacherFeedback
                  if (detail.teacherFeedback != null && detail.teacherFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      Icons.person,
                      'Nhận xét giáo viên',
                      detail.teacherFeedback!,
                      Colors.deepOrange,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Helper để dịch tên điểm thành phần sang tiếng Việt
  String _translateScoreName(String key) {
    switch (key.toLowerCase()) {
      case 'pronunciation':
        return 'Phát âm';
      case 'fluency':
        return 'Trôi chảy';
      case 'coherence':
        return 'Mạch lạc';
      case 'completeness':
        return 'Hoàn chỉnh';
      case 'accuracy':
        return 'Chính xác';
      case 'intonation':
        return 'Ngữ điệu';
      case 'grammar':
        return 'Ngữ pháp';
      case 'vocabulary':
        return 'Từ vựng';
      default:
        return key;
    }
  }

  Widget _buildScoreCard(String title, String score, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            score,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(IconData icon, String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(String audioUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.indigo.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.stop : Icons.play_arrow,
                color: AppColors.primary,
                size: 28,
              ),
              onPressed: () async {
                try {
                  if (_isPlaying) {
                    await _audioPlayer.stop();
                    setState(() {
                      _isPlaying = false;
                    });
                  } else {
                    await _audioPlayer.stop();

                    setState(() {
                      _isPlaying = true;
                    });

                    await _audioPlayer.play(UrlSource(audioUrl));
                  }
                } catch (e) {
                  setState(() {
                    _isPlaying = false;
                  });
                  Get.snackbar('Lỗi', 'Không thể phát audio: $e',
                      backgroundColor: Colors.red.shade100);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bản ghi âm thanh',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying ? 'Đang phát...' : 'Nhấn để phát',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPronunciationAnalysis(List<Map<String, dynamic>> feedbackList) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.graphic_eq, color: Colors.amber),
          ),
          title: const Text(
            'Phân tích phát âm',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            '${feedbackList.length} âm tiết',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        phoneme,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}