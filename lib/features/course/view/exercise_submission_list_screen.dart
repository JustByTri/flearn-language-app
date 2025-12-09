import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/colors.dart';
import '../data/course_service.dart';
import '../model/all_exercise_submit.dart';

class ExerciseSubmissionListScreen extends StatefulWidget {
  final String exerciseId;
  final String exerciseTitle;
  final String exerciseType; // NEW: Thêm exerciseType để biết loại bài tập

  const ExerciseSubmissionListScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseTitle,
    this.exerciseType = '', // NEW: Default empty
  });

  @override
  State<ExerciseSubmissionListScreen> createState() => _ExerciseSubmissionListScreenState();
}

class _ExerciseSubmissionListScreenState extends State<ExerciseSubmissionListScreen> {
  bool _loading = true;
  List<ExerciseSubmission> _submissions = [];
  String? _error;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingUrl;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        if (state == PlayerState.completed) {
          setState(() {
            _currentPlayingUrl = null;
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Xem điểm: ${widget.exerciseTitle}',
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Lỗi: $_error', style: TextStyle(color: Colors.red.shade700, fontSize: 16)),
          ],
        ),
      )
          : _submissions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Chưa có bài nộp nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _submissions.length,
              itemBuilder: (context, i) {
                final sub = _submissions[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: _buildSubmissionCard(sub, i),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(ExerciseSubmission sub, int index) {
    Map<String, dynamic>? aiFeedback;
    try {
      aiFeedback = json.decode(sub.aiFeedback);
    } catch (_) {}

    final scores = aiFeedback?['scores'] as Map<String, dynamic>? ?? {};
    final overall = aiFeedback?['overall']?.toString() ?? sub.aiScore.toString();
    final transcript = aiFeedback?['transcript']?.toString() ?? '';
    final recognizedText = aiFeedback?['recognizedText']?.toString() ?? '';

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
          feedbackList.addAll(List<Map<String, dynamic>>.from(json.decode(feedbackRaw)));
        }
      }
    } catch (_) {}

    final hasTeacherScore = sub.teacherScore > 0;
    final isRepeatAfterMe = widget.exerciseType == 'RepeatAfterMe';

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
        child: SingleChildScrollView(
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
                          Text(
                            'Lần nộp ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sub.submittedAt,
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
                    // Điểm số
                    if (hasTeacherScore)
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
                                  '${sub.aiPercent}% tổng điểm',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildScoreCard(
                                  'Điểm GV',
                                  '${sub.teacherScore}/100',
                                  Icons.person,
                                  Colors.purple,
                                  '${sub.teacherPercent}% tổng điểm',
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
                                  '${sub.finalScore.toStringAsFixed(1)}',
                                  sub.isPassed ? Icons.check_circle : Icons.cancel,
                                  sub.isPassed ? Colors.green : Colors.red,
                                  sub.isPassed ? 'Đạt yêu cầu' : 'Chưa đạt',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildScoreCard(
                                  'Điểm cần đạt',
                                  '${sub.passScore ?? 0}',
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildScoreCard(
                              'Điểm AI',
                              '$overall/100',
                              sub.isPassed ? Icons.check_circle : Icons.cancel,
                              sub.isPassed ? Colors.green : Colors.red,
                              sub.isPassed ? 'Đạt yêu cầu' : 'Chưa đạt',
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildScoreCard(
                            'Điểm cần đạt',
                            '${sub.passScore ?? 0}',
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
                    if (sub.audioUrl.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAudioPlayer(sub.audioUrl),
                    ],

                    // NEW: Điểm thành phần - Lọc bỏ các điểm = 0
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
                                colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
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
                    if (sub.teacherFeedback.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        Icons.person,
                        'Nhận xét giáo viên',
                        sub.teacherFeedback,
                        Colors.deepOrange,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
    final isPlaying = _currentPlayingUrl == audioUrl;

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
                isPlaying ? Icons.stop : Icons.play_arrow,
                color: AppColors.primary,
                size: 28,
              ),
              onPressed: () async {
                try {
                  if (isPlaying) {
                    await _audioPlayer.stop();
                    setState(() {
                      _currentPlayingUrl = null;
                    });
                  } else {
                    await _audioPlayer.stop();

                    setState(() {
                      _currentPlayingUrl = audioUrl;
                    });

                    await _audioPlayer.play(UrlSource(audioUrl));
                  }
                } catch (e) {
                  setState(() {
                    _currentPlayingUrl = null;
                  });
                  Get.snackbar('Lỗi', 'Không thể phát audio: $e', backgroundColor: Colors.red.shade100);
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
                  isPlaying ? 'Đang phát...' : 'Nhấn để phát',
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