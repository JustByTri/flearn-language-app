import 'package:flearn_app/features/course_progress/model/lesson_progress_detail.dart';
import 'package:flearn_app/features/course_progress/viewmodel/course_progress_viewmodel.dart';
import 'package:flearn_app/features/course/view/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../viewmodel/course_viewmodel.dart';
import 'course_exercise_screen.dart';
import 'course_lesson_drawer.dart';

enum LessonStep { content, video, document }

class CourseLessonScreen extends StatefulWidget {
  final String lessonId;
  const CourseLessonScreen({super.key, required this.lessonId});

  @override
  State<CourseLessonScreen> createState() => _CourseLessonScreenState();
}

class _CourseLessonScreenState extends State<CourseLessonScreen> {
  final CourseProgressViewModel progressViewModel = Get.find<CourseProgressViewModel>();
  int _currentStep = 0;
  List<LessonStep> _availableSteps = [];
  List<bool> _stepChecked = [];
  final Set<LessonStep> _loggedSteps = {};
  bool _isLogging = false;
  final CourseViewModel courseViewModel = Get.find<CourseViewModel>();


  late String _lessonId;

  @override
  void initState() {
    super.initState();
    _lessonId = widget.lessonId;
    progressViewModel.fetchLessonProgressDetail(_lessonId);
  }

  @override
  void didUpdateWidget(covariant CourseLessonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonId != widget.lessonId) {
      _lessonId = widget.lessonId;
      progressViewModel.fetchLessonProgressDetail(_lessonId);
      setState(() {
        _currentStep = 0;
        _loggedSteps.clear();
      });
    }
  }

  void _initSteps(LessonProgressDetail detail) {
    final activity = detail.activityStatus;
    final steps = <LessonStep>[];
    if (activity.content.isAvailable) steps.add(LessonStep.content);
    if (activity.video.isAvailable) steps.add(LessonStep.video);
    if (activity.document.isAvailable) steps.add(LessonStep.document);
    if (steps.isEmpty) steps.add(LessonStep.content);

    _availableSteps = steps;
    _stepChecked = [
      if (activity.content.isAvailable) activity.content.isCompleted else false,
      if (activity.video.isAvailable) activity.video.isCompleted else false,
      if (activity.document.isAvailable) activity.document.isCompleted else false,
    ];
    if (_currentStep >= _availableSteps.length) _currentStep = _availableSteps.length - 1;
    if (_currentStep < 0) _currentStep = 0;
  }

  int _indexOf(LessonStep step) => _availableSteps.indexOf(step);
  String _labelOf(LessonStep step) {
    switch (step) {
      case LessonStep.content:
        return 'Nội dung';
      case LessonStep.video:
        return 'Video';
      case LessonStep.document:
        return 'Tài liệu';
    }
  }

  int _logTypeOf(LessonStep step) {
    switch (step) {
      case LessonStep.content:
        return 1;
      case LessonStep.video:
        return 2;
      case LessonStep.document:
        return 3;
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
        title: Obx(() {
          final detail = progressViewModel.lessonProgressDetail.value;
          return Text(
            detail?.unitTitle ?? '',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          );
        }),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppColors.primary),
              tooltip: 'Danh sách bài học',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),

      endDrawer: CourseLessonDrawer(
        currentLessonId: _lessonId,
        onLessonSelected: (newLessonId) {
          if (newLessonId == _lessonId) return;
          // reset state và fetch bài mới
          setState(() {
            _lessonId = newLessonId;
            _currentStep = 0;
            _loggedSteps.clear();
            _availableSteps = [];
            _stepChecked = [];
          });
          // gọi fetch sau khi Drawer đóng hẳn (đã delay ở Drawer), ở đây vẫn an toàn gọi lại
          progressViewModel.fetchLessonProgressDetail(newLessonId);
        },
      ),
      body: Obx(() {
        if (progressViewModel.isLoadingLessonProgress.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final detail = progressViewModel.lessonProgressDetail.value;
        if (detail == null) {
          return const Center(child: Text('Không thể tải dữ liệu bài học'));
        }
        _initSteps(detail);

        return Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCurrentStepContent(detail),
                ),
              ),
            ),
            _buildBottomNavigation(detail),
          ],
        );
      }),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < _availableSteps.length; i++) ...[
            Expanded(child: _buildStepDot(i, _labelOf(_availableSteps[i]))),
            if (i < _availableSteps.length - 1) _buildStepLine(i),
          ],
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : (isActive ? AppColors.primary : Colors.grey.shade300),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.primary : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isCompleted ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildCurrentStepContent(LessonProgressDetail detail) {
    if (_availableSteps.isEmpty) return const SizedBox.shrink();
    final step = _availableSteps[_currentStep];
    final activity = detail.activityStatus;
    switch (step) {
      case LessonStep.content:
        return _buildContentStep(detail, activity);
      case LessonStep.video:
        return _buildVideoStep(detail, activity);
      case LessonStep.document:
        return _buildDocumentStep(detail, activity);
    }
  }

  Widget _buildContentStep(LessonProgressDetail detail, ActivityStatus activity) {
    final idx = _indexOf(LessonStep.content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Bài ${detail.lessonTitle}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          detail.lessonTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (detail.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            detail.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Html(
            data: activity.content.resourceUrl ?? '',
          ),
        ),
        const SizedBox(height: 16),
        if (idx >= 0)
          Row(
            children: [
              Checkbox(
                value: _stepChecked[idx],
                onChanged: (val) {
                  _onStepChecked(LessonStep.content, idx, val ?? false, detail.lessonId);
                },
              ),
              const Text('Đã đọc nội dung bài học'),
            ],
          ),
      ],
    );
  }

  Widget _buildVideoStep(LessonProgressDetail detail, ActivityStatus activity) {
    final idx = _indexOf(LessonStep.video);
    if (idx < 0) return const SizedBox.shrink();

    if (!(activity.video.isAvailable && (activity.video.resourceUrl?.isNotEmpty ?? false))) {
      return _buildEmptyState(
        icon: Icons.video_library_outlined,
        message: 'Bài học này không có video',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video bài học',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: VideoPlayerWidget(videoUrl: activity.video.resourceUrl!),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hãy xem kỹ video để hiểu rõ hơn về bài học này',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Checkbox(
              value: _stepChecked[idx],
              onChanged: (val) {
                _onStepChecked(LessonStep.video, idx, val ?? false, detail.lessonId);
              },
            ),
            const Text('Đã xem video bài học'),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentStep(LessonProgressDetail detail, ActivityStatus activity) {
    final idx = _indexOf(LessonStep.document);
    if (idx < 0) return const SizedBox.shrink();

    if (!(activity.document.isAvailable && (activity.document.resourceUrl?.isNotEmpty ?? false))) {
      return _buildEmptyState(
        icon: Icons.description_outlined,
        message: 'Bài học này không có tài liệu PDF',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tài liệu bài học',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(Icons.picture_as_pdf, size: 80, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                detail.lessonTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tài liệu PDF',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: mở PDF
                  Get.snackbar(
                    'Thông báo',
                    'Chức năng xem PDF đang được phát triển',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Tải tài liệu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tài liệu bổ sung giúp bạn ôn tập và ghi nhớ tốt hơn',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Checkbox(
              value: _stepChecked[idx],
              onChanged: (val) {
                _onStepChecked(LessonStep.document, idx, val ?? false, detail.lessonId);
              },
            ),
            const Text('Đã xem tài liệu bài học'),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(LessonProgressDetail detail) {
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
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
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
                    'Quay lại',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () async {
                  if (_currentStep < _availableSteps.length - 1) {
                    setState(() => _currentStep++);
                  } else {
                    if (_stepChecked.any((c) => !c)) {
                      Get.snackbar('Thông báo', 'Bạn cần hoàn thành tất cả các mục trước khi hoàn thành bài học!',
                          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
                      return;
                    }

                    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);


                    await courseViewModel.fetchLessonExercises(detail.lessonId);

                    if (Get.isDialogOpen ?? false) Get.back();


                    if (courseViewModel.exercises.isNotEmpty) {
                      Get.to(() => LessonExerciseScreen(
                        lessonId: detail.lessonId,
                        lessonTitle: detail.lessonTitle,
                      ));
                    } else {
                      Get.back();
                      Get.snackbar('Hoàn thành', 'Bạn đã hoàn thành bài học ${detail.lessonTitle}!',
                          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                    }
                  }
                },
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
                      _currentStep < _availableSteps.length - 1 ? 'Tiếp theo' : 'Hoàn thành',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentStep < _availableSteps.length - 1 ? Icons.arrow_forward : Icons.check,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStepChecked(LessonStep step, int idx, bool checked, String lessonId) async {
    setState(() {
      _stepChecked[idx] = checked;
    });
    if (!checked) return;
    if (_loggedSteps.contains(step)) return;
    if (_isLogging) return;

    _isLogging = true;
    try {

      await courseViewModel.trackLessonActivity(
        lessonId: lessonId,
        logType: _logTypeOf(step),
        durationMinutes: 0,
        metadata: '',
      );
      _loggedSteps.add(step);
    } catch (e) {
      setState(() {
        _stepChecked[idx] = false;
      });
      Get.snackbar('Lỗi', 'Không thể cập nhật tiến độ. Vui lòng thử lại.');
    } finally {
      _isLogging = false;
    }
  }
}