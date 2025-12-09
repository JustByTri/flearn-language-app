import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/mic_record.dart';

import '../model/course_exercise.dart';
import '../viewmodel/course_viewmodel.dart';
import 'exercise_submission_result_screen.dart';

class ExerciseDebateScreen extends StatefulWidget {
  final String exerciseId;
  const ExerciseDebateScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseDebateScreen> createState() => _ExerciseDebateScreenState();
}

class _ExerciseDebateScreenState extends State<ExerciseDebateScreen> {
  final CourseViewModel vm = Get.find<CourseViewModel>();
  String? _recordedPath;
  String? _submissionId;
  bool _submitted = false;
  bool _isGrading = false;

  // NEW: Trạng thái expandable sections - CHỈ GIỮ LẠI 2 CÁI
  bool _showHints = false;
  bool _showReference = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.fetchExerciseDetail(widget.exerciseId);
    });
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'advanced':
        return Colors.purple;
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
          'Tranh luận',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: false,
      ),
      body: _isGrading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.brown),
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
          return const Center(child: CircularProgressIndicator(color: Colors.brown));
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
                          ex.title.isNotEmpty ? ex.title : 'Tranh luận',
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
                            _buildChip(Icons.forum_rounded, 'Tranh luận', Colors.brown),
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

                  // NEW: "Chủ đề tranh luận" hiện sẵn - TRÊN HÌNH ẢNH
                  if (ex.prompt.isNotEmpty && ex.prompt != 'string') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.brown.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.brown.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.brown, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Chủ đề tranh luận',
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
                    const SizedBox(height: 12),
                  ],

                  // NEW: "Đề bài" hiện sẵn - TRÊN HÌNH ẢNH
                  if (ex.content.isNotEmpty && ex.content != 'string') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.brown.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.brown.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined, color: Colors.brown, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Đề bài',
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
                            ex.content,
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

                  // NEW: Hình ảnh (nếu có) - BÂY GIỜ Ở DƯỚI
                  if (ex.mediaUrls.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          ex.mediaUrls.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.brown)),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
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

                  // NEW: Expandable "Lập luận tham khảo" - GIỮ NGUYÊN
                  if (ex.expectedAnswer.isNotEmpty && ex.expectedAnswer != 'string') ...[
                    _buildExpandableSection(
                      icon: Icons.lightbulb_outline,
                      title: 'Lập luận tham khảo',
                      content: ex.expectedAnswer,
                      isExpanded: _showReference,
                      onTap: () => setState(() => _showReference = !_showReference),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // NEW: Expandable "Gợi ý" - GIỮ NGUYÊN
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
                  Icon(icon, color: Colors.brown, size: 22),
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

  // NEW: Submit button widget
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