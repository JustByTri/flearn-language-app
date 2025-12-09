import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/mic_record.dart';
import '../model/course_exercise.dart';
import '../viewmodel/course_viewmodel.dart';
import 'exercise_submission_result_screen.dart';

class ExerciseFillInBlankScreen extends StatefulWidget {
  final String exerciseId;
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
  bool _isGrading = false;

  // NEW: Trạng thái expandable sections
  bool _showHints = false;
  bool _showReference = false;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.fetchExerciseDetail(widget.exerciseId);
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

  Widget _buildImageCarousel(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal)),
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
        const SizedBox(height: 12),
        // Dots indicator
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Kể chuyện theo tranh',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: false,
      ),
      body: _isGrading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.teal),
            const SizedBox(height: 16),
            const Text(
              'Hệ thống đang chấm điểm cho bạn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      )
          : Obx(() {
        final loading = vm.isLoadingExerciseDetail.value;
        final Exercise? ex = vm.exerciseDetail.value;
        if (loading || ex == null) {
          return const Center(child: CircularProgressIndicator(color: Colors.teal));
        }
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // NEW: Card tiêu đề + chips
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.title.isNotEmpty ? ex.title : 'Kể chuyện theo tranh',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildChip(Icons.menu_book_rounded, 'Kể chuyện', Colors.teal),
                            _buildChip(
                              Icons.speed_rounded,
                              ex.difficulty.isEmpty ? 'Easy' : ex.difficulty,
                              _difficultyColor(ex.difficulty),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // NEW: "Yêu cầu" hiện sẵn - TRÊN HÌNH ẢNH
                  if (ex.prompt.isNotEmpty && ex.prompt != 'string') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.teal, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Yêu cầu',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            ex.prompt,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // NEW: Hình ảnh carousel
                  if (ex.mediaUrls.isNotEmpty) ...[
                    _buildImageCarousel(ex.mediaUrls),
                    const SizedBox(height: 20),
                  ],

                  // NEW: Nút ghi âm to ở giữa
                  Center(
                    child: VoiceRecorder(
                      exerciseId: ex.exerciseID,
                      onRecorded: (p) => setState(() => _recordedPath = p),
                      primaryColor: const Color(0xFF42A5F5),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // NEW: Expandable "Gợi ý kể chuyện"
                  if (ex.content.isNotEmpty && ex.content != 'string') ...[
                    _buildExpandableSection(
                      icon: Icons.tips_and_updates_outlined,
                      title: 'Gợi ý kể chuyện',
                      content: ex.content,
                      isExpanded: _showContent,
                      onTap: () => setState(() => _showContent = !_showContent),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // NEW: Expandable "Đáp án tham khảo"
                  if (ex.expectedAnswer.isNotEmpty && ex.expectedAnswer != 'string') ...[
                    _buildExpandableSection(
                      icon: Icons.lightbulb_outline,
                      title: 'Đáp án tham khảo',
                      content: ex.expectedAnswer,
                      isExpanded: _showReference,
                      onTap: () => setState(() => _showReference = !_showReference),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // NEW: Expandable "Gợi ý"
                  if (ex.hints.isNotEmpty && ex.hints != 'string') ...[
                    _buildExpandableSection(
                      icon: Icons.emoji_objects_outlined,
                      title: 'Gợi ý',
                      content: ex.hints,
                      isExpanded: _showHints,
                      onTap: () => setState(() => _showHints = !_showHints),
                    ),
                  ],
                ],
              ),
            ),

            // NEW: Bottom button fixed
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: _buildSubmitButton(ex),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // NEW: Expandable section widget
  Widget _buildExpandableSection({
    required IconData icon,
    required String title,
    required String content,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: Colors.teal, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                content,
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  // NEW: Submit button widget (giống exercise_debate_screen.dart)
  Widget _buildSubmitButton(Exercise ex) {
    return Obx(() {
      final submitting = vm.isSubmittingExercise.value;
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: submitting
              ? null
              : () async {
            if (_submitted && _submissionId != null) {
              final detail = await vm.fetchSubmissionDetail(_submissionId!);
              if (detail != null) {
                Get.off(() => ExerciseSubmissionResultScreen(detail: detail));
              } else {
                Get.snackbar('Lỗi', 'Không lấy được kết quả',
                    snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
              }
              return;
            }
            if (_recordedPath == null || _recordedPath!.isEmpty) {
              Get.snackbar('Thiếu ghi âm', 'Vui lòng ghi âm câu trả lời trước khi nộp.',
                  snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
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
                  _isGrading = true;
                });
                await Future.delayed(const Duration(seconds: 3));
                if (mounted) {
                  setState(() {
                    _isGrading = false;
                    _submitted = true;
                  });
                }
                Get.snackbar('Thành công', 'Nộp bài thành công! Bấm xem kết quả.',
                    snackPosition: SnackPosition.TOP, backgroundColor: Colors.green, colorText: Colors.white);
              } else {
                Get.snackbar('Lỗi', 'Nộp bài thất bại: Submission ID missing.',
                    snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
              }
            } else {
              final errorMessage = result?['message'] as String? ?? 'Nộp bài thất bại.';
              Get.snackbar('Lỗi', errorMessage,
                  snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
            }
          },
          icon: submitting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : Icon(_submitted ? Icons.visibility : Icons.send, size: 20),
          label: Text(
            submitting ? 'Đang nộp...' : (_submitted ? 'Xem kết quả' : 'Nộp bài'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF42A5F5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      );
    });
  }
}