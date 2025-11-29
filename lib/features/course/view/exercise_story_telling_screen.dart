import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/mic_record.dart';
import '../model/course_exercise.dart';
import '../viewmodel/course_viewmodel.dart';
import 'exercise_submission_result_screen.dart';

class ExerciseFillInBlankScreen extends StatefulWidget {
  final String exerciseId; // Thay Exercise thành String
  const ExerciseFillInBlankScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseFillInBlankScreen> createState() => _ExerciseFillInBlankScreenState();
}

class _ExerciseFillInBlankScreenState extends State<ExerciseFillInBlankScreen> {
  final CourseViewModel vm = Get.find<CourseViewModel>();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _recordedPath;
  String? _submissionId;
  bool _submitted = false;
  bool _isGrading = false; // NEW: biến kiểm soát loading toàn màn

  @override
  void initState() {
    super.initState();
    // Gọi API chi tiết theo exerciseID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.fetchExerciseDetail(widget.exerciseId); // Fetch bằng exerciseId
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  Widget _chip(IconData icon, String text, Color color) {
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

  Widget _buildImageCarousel(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: _pageController,
              itemCount: urls.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => Image.network(
                urls[i],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(urls.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 10 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? Colors.teal : Colors.teal.withOpacity(0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
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
        title: const Text(
          'Kể chuyện/Điền từ',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _isGrading // NEW: nếu đang grading, hiển thị loading toàn màn
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Hệ thống đang chấm điểm cho bạn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      )
          : Obx(() { // NEW: wrap trong _isGrading check
        final loading = vm.isLoadingExerciseDetail.value;
        final Exercise? ex = vm.exerciseDetail.value;  // Dùng nullable, không có ?? widget.exercise
        if (loading || ex == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                      ex.title.isNotEmpty ? ex.title : 'Kể chuyện/Điền từ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _chip(Icons.menu_book_rounded, 'Kể chuyện', Colors.teal),
                        _chip(Icons.speed_rounded, ex.difficulty.isEmpty ? 'Mức độ' : ex.difficulty,
                            _difficultyColor(ex.difficulty)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Hình ảnh (nếu có nhiều ảnh)
              if (ex.mediaUrls.isNotEmpty) ...[
                _buildImageCarousel(ex.mediaUrls),
                const SizedBox(height: 16),
              ],

              if (ex.prompt.isNotEmpty && ex.prompt != 'string') ...[
                _sectionCard(title: 'Yêu cầu', content: ex.prompt),
                const SizedBox(height: 12),
              ],
              if (ex.content.isNotEmpty && ex.content != 'string') ...[
                _sectionCard(title: 'Gợi ý kể chuyện', content: ex.content),
                const SizedBox(height: 12),
              ],
              if (ex.expectedAnswer.isNotEmpty && ex.expectedAnswer != 'string') ...[
                _sectionCard(title: 'Đáp án tham khảo', content: ex.expectedAnswer),
                const SizedBox(height: 12),
              ],
              if (ex.hints.isNotEmpty && ex.hints != 'string') ...[
                _sectionCard(title: 'Gợi ý', content: ex.hints),
              ],
              const SizedBox(height: 16),

              // NEW: Mic ghi âm
              VoiceRecorder(
                exerciseId: ex.exerciseID,
                onRecorded: (p) => setState(() => _recordedPath = p),
                primaryColor: Colors.teal,
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
      bottomNavigationBar: _isGrading ? null : Obx(() { // NEW: ẩn bottomNavigationBar khi grading
        final submitting = vm.isSubmittingExercise.value;
        final Exercise? ex = vm.exerciseDetail.value;  // Dùng nullable
        if (ex == null) return const SizedBox.shrink();  // Ẩn nếu chưa load
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
                      Get.snackbar('Lỗi', 'Không lấy được kết quả', snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
                    }
                    return;
                  }
                  // Nộp bài
                  if (_recordedPath == null || _recordedPath!.isEmpty) {
                    Get.snackbar('Thiếu ghi âm', 'Vui lòng ghi âm câu trả lời trước khi nộp.',
                        snackPosition: SnackPosition.TOP, backgroundColor: Colors.orange, colorText: Colors.white);
                    return;
                  }
                  final result = await vm.submitExercise(
                    exerciseId: ex.exerciseID,
                    audioFilePath: _recordedPath!,
                  );
                  if (result != null && result['success'] == true) {
                    final submissionId = result['submissionId'] as String?;
                    if (submissionId != null) {
                      setState(() {
                        _submissionId = submissionId;
                        _isGrading = true; // NEW: bật loading toàn màn
                      });
                      // NEW: delay 3 giây
                      await Future.delayed(const Duration(seconds: 3));
                      if (mounted) {
                        setState(() {
                          _isGrading = false; // NEW: tắt loading
                          _submitted = true; // NEW: cho phép xem kết quả
                        });
                      }
                      Get.snackbar('Thành công', 'Nộp bài thành công! Bấm xem kết quả.', snackPosition: SnackPosition.TOP, backgroundColor: Colors.green, colorText: Colors.white);
                    } else {
                      Get.snackbar('Lỗi', 'Nộp bài thất bại: Submission ID missing.', snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  } else {
                    // Use the detailed message from the result
                    final errorMessage = result?['message'] as String? ?? 'Nộp bài thất bại.';
                    Get.snackbar('Lỗi', errorMessage, snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
                  }
                },
                icon: submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_submitted ? Icons.visibility : Icons.send),
                label: Text(submitting
                    ? 'Đang nộp...'
                    : (_submitted ? 'Xem kết quả' : 'Nộp bài')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
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
}