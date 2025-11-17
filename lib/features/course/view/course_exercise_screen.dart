import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../model/course_exercise.dart';
import '../viewmodel/course_viewmodel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'exercise_story_telling_screen.dart';
import 'exercise_picture_description_screen.dart';
import 'exercise_repeat_after_me_screen.dart';
import 'exercise_debate_screen.dart';

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

      // chuyển bài khi API 200
      _nextExercise();


  }

  // NEW: card hiển thị 1 bài tập
  Widget _buildExerciseItem(Exercise e, int index) {
    final Color typeColor = _getExerciseTypeColor(e.exerciseType);
    final IconData typeIcon = _getExerciseTypeIcon(e.exerciseType);

    return InkWell(
      onTap: () => _goToExercisePage(e),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Index badge
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: typeColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title + chips + prompt
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    e.title.isNotEmpty ? e.title : _getExerciseTypeLabel(e.exerciseType),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Chips: type + difficulty
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: typeColor.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 14, color: typeColor),
                            const SizedBox(width: 6),
                            Text(
                              _getExerciseTypeLabel(e.exerciseType),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: typeColor),
                            ),
                          ],
                        ),
                      ),
                      _buildDifficultyChip(e.difficulty),
                    ],
                  ),
                  if (e.prompt.isNotEmpty && e.prompt != 'string') ...[
                    const SizedBox(height: 6),
                    Text(
                      e.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

// NEW: icon theo loại bài tập
  IconData _getExerciseTypeIcon(String type) {
    switch (type) {
      case 'RepeatAfterMe':
        return Icons.mic_rounded;
      case 'PictureDescription':
        return Icons.quiz_rounded;
      case 'StoryTelling':
        return Icons.edit_note_rounded;
      case 'Debate': // NEW
        return Icons.forum_rounded;
      default:
        return Icons.school_rounded;
    }
  }

// NEW: màu theo loại bài tập
  Color _getExerciseTypeColor(String type) {
    switch (type) {
      case 'RepeatAfterMe':
        return AppColors.primary;
      case 'PictureDescription':
        return Colors.deepPurple;
      case 'StoryTelling':
        return Colors.teal;
      case 'Debate': // NEW
        return Colors.brown;
      default:
        return Colors.indigo;
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

        // Sort theo position nếu có
        final items = [...courseViewModel.exercises]..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildExerciseItem(items[index], index),
        );
      }),
    );
  }

  String _getExerciseTypeLabel(String type) {
    switch (type) {
      case 'RepeatAfterMe':
        return 'Lặp lại theo mẫu';
      case 'PictureDescription':
        return 'Mô tả tranh';
      case 'StoryTelling':
        return 'Kể chuyện';
      case 'Debate': // NEW
        return 'Tranh luận';
      default:
        return 'Luyện phát âm';
    }
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
      case 'advanced': // NEW
        color = Colors.purple;
        label = 'Nâng cao';
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

  void _goToExercisePage(Exercise exercise) {
    switch (exercise.exerciseType) {
      case 'RepeatAfterMe':
        Get.to(() => ExerciseRepeatAfterMeScreen(exercise: exercise));
        break;
      case 'PictureDescription':
        Get.to(() => ExerciseMultipleChoiceScreen(exercise: exercise));
        break;
      case 'StoryTelling':
        Get.to(() => ExerciseFillInBlankScreen(exercise: exercise));
        break;
      case 'Debate': // NEW
        Get.to(() => ExerciseDebateScreen(exercise: exercise));
        break;
      default:
        Get.to(() => ExerciseRepeatAfterMeScreen(exercise: exercise));
        break;
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