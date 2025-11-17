import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/mic_record.dart';
import '../model/course_exercise.dart';
import '../viewmodel/course_viewmodel.dart';
import 'exercise_submission_result_screen.dart';


class ExerciseRepeatAfterMeScreen extends StatefulWidget {
  final Exercise exercise; // nhận item từ list để có dữ liệu ban đầu
  const ExerciseRepeatAfterMeScreen({super.key, required this.exercise});

  @override
  State<ExerciseRepeatAfterMeScreen> createState() => _ExerciseRepeatAfterMeScreenState();
}

class _ExerciseRepeatAfterMeScreenState extends State<ExerciseRepeatAfterMeScreen> {
  final CourseViewModel vm = Get.find<CourseViewModel>();
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _recordedPath;
  String? _submissionId;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // gọi API lấy chi tiết theo exerciseID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.fetchExerciseDetail(widget.exercise.exerciseID);
    });
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playSample(String url) async {
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }
    try {
      setState(() => _isPlaying = true);
      await _player.play(UrlSource(url));
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
      Get.snackbar('Lỗi', 'Không thể phát audio mẫu');
    }
  }

  Widget _buildChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
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
        title: const Text('Lặp lại theo mẫu',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Obx(() {
        final loading = vm.isLoadingExerciseDetail.value;
        final Exercise ex = vm.exerciseDetail.value ?? widget.exercise;
        if (loading && vm.exerciseDetail.value == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card tiêu đề + chips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.title.isNotEmpty ? ex.title : 'Lặp lại theo mẫu',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildChip(Icons.mic_rounded, 'Lặp lại theo mẫu', AppColors.primary),
                        _buildChip(Icons.speed_rounded, ex.difficulty.isEmpty ? 'Mức độ' : ex.difficulty,
                            _difficultyColor(ex.difficulty)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Audio mẫu (nếu có)
              if (ex.mediaUrls.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Nghe mẫu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            SizedBox(height: 6),
                            Text('Hãy nghe kỹ ngữ điệu và phát âm trước khi lặp lại.'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _playSample(ex.mediaUrls.first),
                        icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                        label: Text(_isPlaying ? 'Dừng' : 'Phát'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Yêu cầu
              if (ex.prompt.isNotEmpty && ex.prompt != 'string') ...[
                _sectionCard(title: 'Yêu cầu', content: ex.prompt),
                const SizedBox(height: 12),
              ],

              // Nội dung mẫu
              if (ex.content.isNotEmpty && ex.content != 'string') ...[
                _sectionCard(title: 'Nội dung mẫu', content: ex.content),
                const SizedBox(height: 12),
              ],

              // Gợi ý
              if (ex.hints.isNotEmpty && ex.hints != 'string') ...[
                _sectionCard(title: 'Gợi ý', content: ex.hints),
              ],
              const SizedBox(height: 16),

              // NEW: Mic ghi âm
              VoiceRecorder(
                exerciseId: ex.exerciseID,
                onRecorded: (p) => setState(() => _recordedPath = p),
                primaryColor: AppColors.primary,
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
      // NEW: bottom submit
      bottomNavigationBar: Obx(() {
        final submitting = vm.isSubmittingExercise.value;
        final Exercise ex = vm.exerciseDetail.value ?? widget.exercise;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: submitting
                    ? null
                    : () async {
                  if (_submitted && _submissionId != null) {
                    // Xem kết quả
                    final detail = await vm.fetchSubmissionDetail(_submissionId!);
                    if (detail != null) {
                      Get.off(() => ExerciseSubmissionResultScreen(detail: detail));
                    } else {
                      Get.snackbar('Lỗi', 'Không lấy được kết quả', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
                    }
                    return;
                  }
                  // Nộp bài
                  if (_recordedPath == null || _recordedPath!.isEmpty) {
                    Get.snackbar('Thiếu ghi âm', 'Vui lòng ghi âm câu trả lời trước khi nộp.',
                        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
                    return;
                  }
                  final submissionId = await vm.submitExercise(
                    exerciseId: ex.exerciseID,
                    audioFilePath: _recordedPath!,
                  );
                  if (submissionId != null) {
                    setState(() {
                      _submissionId = submissionId;
                      _submitted = true;
                    });
                    Get.snackbar('Thành công', 'Nộp bài thành công! Bấm xem kết quả.', snackPosition: SnackPosition.TOP, backgroundColor: Colors.green, colorText: Colors.white);
                  } else {
                    Get.snackbar('Lỗi', 'Nộp bài thất bại.', snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
                  }
                },
                icon: submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_submitted ? Icons.visibility : Icons.send),
                label: Text(submitting
                    ? 'Đang nộp...'
                    : (_submitted ? 'Xem kết quả' : 'Nộp bài')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _sectionCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}