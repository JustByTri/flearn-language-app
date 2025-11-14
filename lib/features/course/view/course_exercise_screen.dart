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
// NEW: player riêng để phát ghi âm người dùng
  final AudioPlayer _recordPlayer = AudioPlayer();

  int _currentExerciseIndex = 0;
  bool _isPlayingAudio = false;
// NEW
  bool _isPlayingRecord = false;

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
    // NEW: dispose player ghi âm
    _recordPlayer.dispose();
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
      // dừng phát ghi âm nếu đang phát
      if (_isPlayingRecord) {
        await _recordPlayer.stop();
        setState(() => _isPlayingRecord = false);
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

  // NEW: play/pause ghi âm đã thu
  Future<void> _playRecorded(String path) async {
    if (_isPlayingRecord) {
      await _recordPlayer.stop();
      setState(() => _isPlayingRecord = false);
      return;
    }
    try {
      // dừng audio mẫu nếu đang phát
      if (_isPlayingAudio) {
        await _audioPlayer.stop();
        setState(() => _isPlayingAudio = false);
      }
      setState(() => _isPlayingRecord = true);
      await _recordPlayer.play(DeviceFileSource(path));
      _recordPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingRecord = false);
      });
    } catch (e) {
      setState(() => _isPlayingRecord = false);
      Get.snackbar('Lỗi', 'Không thể phát ghi âm');
    }
  }

  // NEW: UI khối ghi âm (thêm nghe lại + ghi lại)
  Widget _buildRecorder(String exerciseId) {
    final recorded = _recordedFiles[exerciseId];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main record button
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? Colors.red : AppColors.primary).withOpacity(0.4),
                  blurRadius: 16,
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
                _isRecording ? Icons.stop_rounded : Icons.mic,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Status text
          Text(
            _isRecording
                ? _fmt(_recordingDuration)
                : (recorded != null && recorded.isNotEmpty
                ? '✓ Đã ghi âm'
                : 'Nhấn để ghi âm'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _isRecording
                  ? Colors.red.shade700
                  : (recorded != null && recorded.isNotEmpty
                  ? Colors.green.shade700
                  : Colors.grey.shade700),
            ),
          ),
          // Action buttons (chỉ hiện khi đã ghi)
          if (recorded != null && recorded.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Play button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _playRecorded(recorded),
                    icon: Icon(
                      _isPlayingRecord ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      size: 32,
                      color: AppColors.primary,
                    ),
                    tooltip: _isPlayingRecord ? 'Tạm dừng' : 'Nghe lại',
                  ),
                ),
                const SizedBox(width: 20),
                // Re-record button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      setState(() {
                        _recordedFiles.remove(exerciseId);
                        _recordingDuration = Duration.zero;
                      });
                      await _startRecording(exerciseId);
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 32,
                      color: Colors.orange,
                    ),
                    tooltip: 'Ghi lại',
                  ),
                ),
              ],
            ),
          ],
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

  // NEW: submit current exercise -> gọi API, success (200) mới chuyển bài
  Future<void> _submitCurrentExercise() async {
    // đảm bảo dừng ghi
    if (_isRecording) {
      final id = courseViewModel.exercises[_currentExerciseIndex].exerciseID;
      await _stopRecording(id);
    }

    final exercise = courseViewModel.exercises[_currentExerciseIndex];
    final path = _recordedFiles[exercise.exerciseID];

    if (path == null || path.isEmpty) {
      Get.snackbar('Thiếu ghi âm', 'Vui lòng ghi âm câu trả lời trước khi nộp.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final ok = await courseViewModel.submitExercise(exerciseId: exercise.exerciseID, audioFilePath: path);
    if (ok) {
      // chuyển bài khi API 200
      _nextExercise();
    } else {
      Get.snackbar('Lỗi', 'Nộp bài thất bại. Vui lòng thử lại.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
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
            // Progress bar với header
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bài ${_currentExerciseIndex + 1}/${courseViewModel.exercises.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        _buildDifficultyChip(exercise.difficulty),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Exercise type badge
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mic, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              _getExerciseTypeLabel(exercise.exerciseType),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Prompt (nếu có)
                    if (exercise.prompt.isNotEmpty && exercise.prompt != 'string') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                exercise.prompt,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Audio player với từ hiển thị
                    if (exercise.mediaUrls.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.05),
                              Colors.blue.shade50.withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            // Từ cần phát âm (chỉ hiện 1 lần)
                            if (exercise.expectedAnswer.isNotEmpty && exercise.expectedAnswer != 'string') ...[
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade200,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  exercise.expectedAnswer,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            // Play button
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () => _playAudio(exercise.mediaUrls.first),
                                icon: Icon(
                                  _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isPlayingAudio ? 'Đang phát...' : '🎧 Nhấn để nghe mẫu',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Hints (nếu có)
                    if (exercise.hints.isNotEmpty && exercise.hints != 'string') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gợi ý',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exercise.hints,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Recorder
                    _buildRecorder(exercise.exerciseID),
                    const SizedBox(height: 16),
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
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, -2))],
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Bài trước',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ),
            if (_currentExerciseIndex > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Obx(() {
                final submitting = courseViewModel.isSubmittingExercise.value;
                return ElevatedButton(
                  onPressed: submitting ? null : _submitCurrentExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (submitting) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        'Nộp bài',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Icon(isLastExercise ? Icons.send : Icons.send, size: 20),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}