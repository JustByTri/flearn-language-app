import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../viewmodel/course_viewmodel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class LessonExerciseScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const LessonExerciseScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<LessonExerciseScreen> createState() => _LessonExerciseScreenState();
}

class _LessonExerciseScreenState extends State<LessonExerciseScreen> {
  final CourseViewModel courseViewModel = Get.find<CourseViewModel>();
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _currentExerciseIndex = 0;
  bool _isPlayingAudio = false;

  // NEW: recording state
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordTimer;
  // Lưu file ghi âm theo exerciseId
  final Map<String, String> _recordedFiles = {};

  @override
  void initState() {
    super.initState();
    courseViewModel.fetchLessonExercises(widget.lessonId);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    // NEW: cleanup recorder
    _recordTimer?.cancel();
    _recorder.stop();
    _recorder.dispose();
    super.dispose();
  }

  // NEW: format mm:ss
  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(d.inSeconds.remainder(60)).toString().padLeft(2, '0')}';
  // NEW: bắt đầu ghi âm cho exercise
  Future<void> _startRecording(String exerciseId) async {
    try {
      // dừng audio mẫu nếu đang phát
      if (_isPlayingAudio) {
        await _audioPlayer.stop();
        setState(() => _isPlayingAudio = false);
      }

      // xin quyền
      bool hasPerm = await _recorder.hasPermission() ?? false;
      if (!hasPerm) {
        final st = await Permission.microphone.request();
        if (!st.isGranted) {
          Get.snackbar('Thông báo', 'Cần quyền micro để ghi âm');
          return;
        }
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/exercise_${exerciseId}_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingDuration += const Duration(seconds: 1));
      });
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể bắt đầu ghi âm');
    }
  }

  // NEW: dừng ghi âm và lưu file
  Future<void> _stopRecording(String exerciseId) async {
    try {
      final path = await _recorder.stop();
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        if (path != null && path.isNotEmpty) {
          _recordedFiles[exerciseId] = path;
        }
      });
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể dừng ghi âm');
    }
  }

  // NEW: UI khối ghi âm
  Widget _buildRecorder(String exerciseId) {
    final recorded = _recordedFiles[exerciseId];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi âm câu trả lời',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : AppColors.primary)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () async {
                    if (_isRecording) {
                      await _stopRecording(exerciseId);
                    } else {
                      await _startRecording(exerciseId);
                    }
                  },
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRecording
                          ? 'Đang ghi... ${_fmt(_recordingDuration)}'
                          : (recorded != null && recorded.isNotEmpty
                          ? 'Đã ghi âm: ${File(recorded).uri.pathSegments.last}'
                          : 'Nhấn để bắt đầu ghi'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _isRecording
                            ? Colors.red.shade700
                            : Colors.grey.shade700,
                        fontWeight:
                        _isRecording ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (recorded != null && recorded.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'File: $recorded',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _playAudio(String audioUrl) async {
    if (_isPlayingAudio) {
      await _audioPlayer.stop();
      setState(() => _isPlayingAudio = false);
      return;
    }
    try {
      setState(() => _isPlayingAudio = true);
      await _audioPlayer.play(UrlSource(audioUrl));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingAudio = false);
      });
    } catch (e) {
      setState(() => _isPlayingAudio = false);
      Get.snackbar('Lỗi', 'Không thể phát audio');
    }
  }

  void _nextExercise() async {
    // NEW: đảm bảo dừng ghi khi chuyển bài
    if (_isRecording) {
      final id = courseViewModel.exercises[_currentExerciseIndex].exerciseID;
      await _stopRecording(id);
    }
    if (_currentExerciseIndex < courseViewModel.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    } else {
      Get.back();
      Get.snackbar(
        'Hoàn thành',
        'Bạn đã hoàn thành tất cả bài tập!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (courseViewModel.isLoadingExercises.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (courseViewModel.exercises.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Không có bài tập nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Bài học này chưa có bài tập', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        final exercise = courseViewModel.exercises[_currentExerciseIndex];
        final progress = (_currentExerciseIndex + 1) / courseViewModel.exercises.length;

        return Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              minHeight: 8,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bài tập ${_currentExerciseIndex + 1}/${courseViewModel.exercises.length}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        _buildDifficultyChip(exercise.difficulty),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mic, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            _getExerciseTypeLabel(exercise.exerciseType),
                            style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (exercise.prompt.isNotEmpty && exercise.prompt != 'string') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                exercise.prompt,
                                style: TextStyle(fontSize: 15, color: Colors.blue.shade900, height: 1.5, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (exercise.mediaUrls.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withOpacity(0.1), Colors.blue.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () => _playAudio(exercise.mediaUrls.first),
                                icon: Icon(
                                  _isPlayingAudio ? Icons.pause : Icons.play_arrow,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🎧 Nghe phát âm mẫu',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isPlayingAudio ? 'Đang phát...' : 'Nhấn để nghe',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (exercise.expectedAnswer.isNotEmpty && exercise.expectedAnswer != 'string') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          exercise.expectedAnswer,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (exercise.hints.isNotEmpty && exercise.hints != 'string') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.tips_and_updates, color: Colors.amber.shade700, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '💡 Gợi ý phát âm',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exercise.hints,
                                    style: TextStyle(fontSize: 14, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // NEW: Recorder block
                    const SizedBox(height: 8),
                    _buildRecorder(exercise.exerciseID),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.purple.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ' Điểm tối đa: ${exercise.maxScore} | Điểm đạt: ${exercise.passScore}',
                              style: TextStyle(fontSize: 13, color: Colors.purple.shade900, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        );
      }),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color color;
    String label;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green;
        label = 'Dễ';
        break;
      case 'medium':
        color = Colors.orange;
        label = 'Trung bình';
        break;
      case 'hard':
        color = Colors.red;
        label = 'Khó';
        break;
      default:
        color = Colors.grey;
        label = difficulty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  String _getExerciseTypeLabel(String type) {
    switch (type) {
      case 'RepeatAfterMe':
        return 'Lặp lại theo mẫu';
      case 'MultipleChoice':
        return 'Trắc nghiệm phát âm';
      case 'FillInTheBlank':
        return 'Điền từ thiếu';
      default:
        return 'Luyện phát âm';
    }
  }

  Widget _buildBottomButtons() {
    final isLastExercise = _currentExerciseIndex == courseViewModel.exercises.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentExerciseIndex > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentExerciseIndex--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Bài trước',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
            if (_currentExerciseIndex > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _nextExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastExercise ? 'Hoàn thành' : 'Bài tiếp theo',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Icon(isLastExercise ? Icons.check : Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}