import 'package:flearn_app/features/course_progress/model/lesson_progress_detail.dart';
import 'package:flearn_app/features/course_progress/viewmodel/course_progress_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../../shared/widgets/video_player.dart';
import '../model/course_exercise.dart';
import '../model/lesson_progress_exercise.dart';
import '../viewmodel/course_viewmodel.dart';
import 'course_exercise_screen.dart';
import 'course_lesson_drawer.dart';
import 'exercise_debate_screen.dart';
import 'exercise_picture_description_screen.dart';
import 'exercise_repeat_after_me_screen.dart';
import 'exercise_story_telling_screen.dart';
import 'exercise_submission_list_screen.dart';
import 'pdf_view_screen.dart';

enum LessonStep {
  content,
  video,
  document,
  exercise,
} // NEW

class CourseLessonScreen extends StatefulWidget {
  final String lessonId;
  const CourseLessonScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<CourseLessonScreen> createState() =>
      _CourseLessonScreenState();
}

class _CourseLessonScreenState extends State<CourseLessonScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController =
  ScrollController(); // Thêm controller
  final CourseProgressViewModel progressViewModel =
  Get.find<CourseProgressViewModel>();
  final CourseViewModel courseViewModel =
  Get.find<CourseViewModel>();
  int _currentStep = 0;
  List<LessonStep> _availableSteps = [];
  List<bool> _stepChecked = [];
  final Set<LessonStep> _loggedSteps = {};
  bool _isLogging = false;
  String? _initedForLessonId;

  late String _lessonId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add this if not already present
    _lessonId = widget.lessonId;
    progressViewModel.fetchLessonProgressDetail(_lessonId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Re-fetch lesson progress detail when app resumes (e.g., back from exercise)
      progressViewModel.fetchLessonProgressDetail(_lessonId);
    }
  }

  @override
  void didUpdateWidget(
      covariant CourseLessonScreen oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonId != widget.lessonId) {
      _lessonId = widget.lessonId;
      _initedForLessonId =
      null; // NEW: reset để init lại cho bài mới
      progressViewModel.fetchLessonProgressDetail(
        _lessonId,
      );
      setState(() {
        _currentStep = 0;
        _loggedSteps.clear();
      });
    }
  }

  void _initSteps(LessonProgressDetail detail) {
    final activity = detail.activityStatus;

    final steps = <LessonStep>[];
    if (activity.content.isAvailable)
      steps.add(LessonStep.content);
    if (activity.video.isAvailable)
      steps.add(LessonStep.video);
    if (activity.document.isAvailable)
      steps.add(LessonStep.document);
    if (steps.isEmpty) steps.add(LessonStep.content);

    _availableSteps = steps;

    // Chỉ thêm trạng thái cho step thực sự có
    _stepChecked = [];
    _loggedSteps.clear();
    for (final s in _availableSteps) {
      bool completed = switch (s) {
        LessonStep.content => activity.content.isCompleted,
        LessonStep.video => activity.video.isCompleted,
        LessonStep.document =>
        activity.document.isCompleted,
        LessonStep.exercise =>
        false, // exercise không có checkbox
      };
      _stepChecked.add(completed);
      if (completed && s != LessonStep.exercise) {
        _loggedSteps.add(s);
      }
    }

    // Prefetch bài tập và chèn step Exercise nếu có dữ liệu
    courseViewModel
        .fetchLessonProgressExercises(detail.lessonId)
        .then((_) {
      if (!mounted) return;
      if (courseViewModel.progressExercises.isNotEmpty &&  // Dùng RxList mới
          !_availableSteps.contains(
            LessonStep.exercise,
          )) {
        setState(() {
          _availableSteps.add(LessonStep.exercise);
          _stepChecked.add(detail.isAllExercisesPassed);  // UPDATED: Use API field instead of false
          if (_currentStep >= _availableSteps.length) {
            _currentStep = _availableSteps.length - 1;
          }
        });
      }
    });

    // NEW: Tìm step đầu tiên chưa hoàn thành và set _currentStep
    int firstIncompleteIndex = _stepChecked.indexWhere(
          (checked) => !checked,
    );
    if (firstIncompleteIndex != -1) {
      _currentStep = firstIncompleteIndex;
    } else {
      _currentStep =
          _availableSteps.length -
              1; // Nếu tất cả hoàn thành, ở step cuối (thường là exercise)
    }

    if (_currentStep >= _availableSteps.length)
      _currentStep = _availableSteps.length - 1;
    if (_currentStep < 0) _currentStep = 0;
  }

  int _indexOf(LessonStep step) =>
      _availableSteps.indexOf(step);
  String _labelOf(LessonStep step) {
    switch (step) {
      case LessonStep.content:
        return 'Nội dung';
      case LessonStep.video:
        return 'Video';
      case LessonStep.document:
        return 'Tài liệu';
      case LessonStep.exercise:
        return 'Bài tập'; // NEW
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
      case LessonStep.exercise:
        return 0; // không log
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
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          final detail =
              progressViewModel.lessonProgressDetail.value;
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
              icon: const Icon(
                Icons.menu,
                color: AppColors.primary,
              ),
              tooltip: 'Danh sách bài học',
              onPressed: () =>
                  Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),

      endDrawer: CourseLessonDrawer(
        currentLessonId: _lessonId,
        onLessonSelected: (newLessonId) {
          if (newLessonId == _lessonId) return;
          setState(() {
            _lessonId = newLessonId;
            _currentStep = 0;
            _loggedSteps.clear();
            _availableSteps = [];
            _stepChecked = [];
            _initedForLessonId = null; // NEW
          });
          progressViewModel.fetchLessonProgressDetail(
            newLessonId,
          );
        },
      ),
      body: Obx(() {
        if (progressViewModel
            .isLoadingLessonProgress
            .value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final detail =
            progressViewModel.lessonProgressDetail.value;
        if (detail == null) {
          return const Center(
            child: Text('Không thể tải dữ liệu bài học'),
          );
        }

        if (_initedForLessonId != detail.lessonId ||
            _availableSteps.isEmpty ||
            _stepChecked.isEmpty) {
          _initSteps(detail);
          _initedForLessonId = detail.lessonId;
        }

        return Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Gọi hàm reload dữ liệu ở đây
                  await progressViewModel.fetchLessonProgressDetail(_lessonId);
                },
                // SỬA ĐỔI: Kiểm tra nếu là step Exercise thì KHÔNG dùng SingleChildScrollView
                // để tránh xung đột cuộn với ListView bên trong ExerciseScreen.
                child: (_availableSteps.isNotEmpty &&
                    _availableSteps[_currentStep] == LessonStep.exercise)
                    ? _buildCurrentStepContent(detail)
                    : SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: _buildCurrentStepContent(detail),
                  ),
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
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
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
          for (
          int i = 0;
          i < _availableSteps.length;
          i++
          ) ...[
            Expanded(
              child: _buildStepDot(
                i,
                _labelOf(_availableSteps[i]),
              ),
            ),
            if (i < _availableSteps.length - 1)
              _buildStepLine(i),
          ],
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted =
        _stepChecked.length > step && _stepChecked[step];

    return InkWell(
      onTap: () {
        setState(() {
          _currentStep = step;
        });
      },
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green
                  : (isActive
                  ? AppColors.primary
                  : Colors.grey.shade300),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              )
                  : Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : Colors.grey.shade600,
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
              color: isActive
                  ? AppColors.primary
                  : Colors.grey.shade600,
              fontWeight: isActive
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isCompleted
            ? Colors.green
            : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildCurrentStepContent(
      LessonProgressDetail detail,
      ) {
    if (_availableSteps.isEmpty)
      return const SizedBox.shrink();
    final step = _availableSteps[_currentStep];
    final activity = detail.activityStatus;
    switch (step) {
      case LessonStep.content:
        return _buildContentStep(detail, activity);
      case LessonStep.video:
        return _buildVideoStep(detail, activity);
      case LessonStep.document:
        return _buildDocumentStep(detail, activity);
      case LessonStep.exercise:
        return CourseLessonExerciseScreen(lessonId: detail.lessonId);
    }
  }

  Widget _buildContentStep(
      LessonProgressDetail detail,
      ActivityStatus activity,
      ) {
    final idx = _indexOf(LessonStep.content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: HtmlWidget(
            activity.content.resourceUrl ?? '',
            textStyle: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: Color(0xFF333333),
            ),
            customStylesBuilder: (element) {
              if (element.localName == 'body') {
                return {
                  'font-family': 'Arial, sans-serif',
                  'line-height': '1.6',
                };
              }
              if (element.className == 'container') {
                return {
                  'max-width': '900px',
                  'margin': 'auto',
                };
              }
              if (element.localName == 'h1') {
                return {
                  'color': '#0056b3',
                  'border-bottom': '2px solid #0056b3',
                  'padding-bottom': '10px',
                  'font-size': '28px',
                };
              }
              if (element.localName == 'h2') {
                return {
                  'color': '#28a745',
                  'margin-top': '25px',
                  'font-size': '22px',
                };
              }
              if (element.localName == 'h3') {
                return {
                  'color': '#ffc107',
                  'margin-top': '15px',
                  'font-size': '18px',
                };
              }
              if (element.className == 'context-box') {
                return {
                  'background-color': '#f8f9fa',
                  'border-left': '5px solid #007bff',
                  'padding': '15px',
                  'margin': '15px 0',
                  'border-radius': '0 8px 8px 0',
                };
              }
              if (element.localName == 'strong' &&
                  element.parent?.localName == 'li') {
                return {'color': '#dc3545'};
              }
              if (element.localName == 'table') {
                return {
                  'width': '100%',
                  'border-collapse': 'collapse',
                  'margin-top': '15px',
                };
              }
              if (element.localName == 'th') {
                return {
                  'background-color': '#e9ecef',
                  'padding': '12px',
                  'text-align': 'left',
                  'border': '1px solid #ddd',
                };
              }
              if (element.localName == 'td') {
                return {
                  'padding': '12px',
                  'border': '1px solid #ddd',
                };
              }
              return null;
            },
            enableCaching: true,
            rebuildTriggers: [activity.content.resourceUrl],
          ),
        ),
        const SizedBox(height: 20),
        if (idx >= 0)
          Row(
            children: [
              Checkbox(
                value: _stepChecked[idx],
                onChanged: _stepChecked[idx]
                    ? null
                    : (val) {
                  _onStepChecked(
                    LessonStep.content,
                    idx,
                    val ?? false,
                    detail.lessonId,
                  );
                },
              ),
              const Text(
                'Đã đọc nội dung bài học',
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildVideoStep(
      LessonProgressDetail detail,
      ActivityStatus activity,
      ) {
    final idx = _indexOf(LessonStep.video);
    if (idx < 0) return const SizedBox.shrink();

    if (!(activity.video.isAvailable &&
        (activity.video.resourceUrl?.isNotEmpty ??
            false))) {
      return _buildEmptyState(
        icon: Icons.video_library_outlined,
        message: 'Bài học này không có video',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề
        const Text(
          'Video bài học',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        SimpleVideoPlayer(
          videoUrl: activity.video.resourceUrl!,
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2196F3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Colors.blue.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hãy xem kỹ video/hướng dẫn để nắm rõ kiến thức và hoàn thành bài hiệu quả hơn nhé.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _stepChecked[idx],
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: _stepChecked[idx]
                  ? null
                  : (val) {
                _onStepChecked(
                  LessonStep.video,
                  idx,
                  val ?? false,
                  detail.lessonId,
                );
              },
            ),
            const Text(
              'Đã xem xong video bài học',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentStep(
      LessonProgressDetail detail,
      ActivityStatus activity,
      ) {
    final idx = _indexOf(LessonStep.document);
    if (idx < 0) return const SizedBox.shrink();

    if (!(activity.document.isAvailable &&
        (activity.document.resourceUrl?.isNotEmpty ??
            false))) {
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
              Icon(
                Icons.picture_as_pdf,
                size: 80,
                color: Colors.red.shade400,
              ),
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
                  final url = activity.document.resourceUrl;
                  if (url != null && url.isNotEmpty) {
                    Get.to(
                          () => PdfViewScreen(
                        pdfUrl: url,
                        title: detail.lessonTitle,
                      ),
                    );
                  } else {
                    Get.snackbar(
                      'Lỗi',
                      'Không tìm thấy tài liệu PDF',
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Xem tài liệu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: 20,
              ),
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
              onChanged: _stepChecked[idx]
                  ? null
                  : (val) {
                _onStepChecked(
                  LessonStep.document,
                  idx,
                  val ?? false,
                  detail.lessonId,
                );
              },
            ),
            const Text('Đã xem tài liệu bài học'),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade300,
            ),
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

  Widget _buildBottomNavigation(
      LessonProgressDetail detail,
      ) {
    // NEW: bỏ qua step Exercise khi tính hoàn thành
    final allCompleted =
        _stepChecked.isNotEmpty &&
            List.generate(
              _availableSteps.length,
                  (i) => _availableSteps[i] == LessonStep.exercise
                  ? true
                  : _stepChecked[i],
            ).every((c) => c);
    final isLastStep =
        _currentStep == _availableSteps.length - 1;

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
            if (_availableSteps.length > 1)
              Expanded(
                child: OutlinedButton(
                  onPressed: _currentStep > 0
                      ? () => setState(() => _currentStep--)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    side: const BorderSide(
                      color: AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
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
            if (_availableSteps.length > 1)
              const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () async {
                  if (!isLastStep) {
                    setState(
                          () => _currentStep =
                          (_currentStep + 1).clamp(
                            0,
                            _availableSteps.length - 1,
                          ),
                    );
                    return;
                  }

                  if (!allCompleted) {
                    Get.snackbar(
                      'Thông báo',
                      'Bạn cần hoàn thành tất cả các mục trước khi hoàn thành bài học!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  // Chuyển về trang unit
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastStep
                          ? 'Hoàn thành'
                          : 'Tiếp theo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastStep
                          ? Icons.check
                          : Icons.arrow_forward,
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

  Future<void> _onStepChecked(
      LessonStep step,
      int idx,
      bool checked,
      String lessonId,
      ) async {
    // Nếu đã completed (từ server) hoặc đã log rồi ⇒ không làm lại
    if (_loggedSteps.contains(step) || _stepChecked[idx]) {
      setState(() {
        _stepChecked[idx] = true;
      });
      Get.snackbar(
        'Thông báo',
        'Mục này đã được hoàn thành.',
      );
      return;
    }
    if (!checked) return;

    // Hiệu ứng UI ngay
    setState(() {
      _stepChecked[idx] = true;
    });

    if (_isLogging) return;
    _isLogging = true;
    _loggedSteps.add(step);

    try {
      await courseViewModel.trackLessonActivity(
        lessonId: lessonId,
        logType: _logTypeOf(step),
        durationMinutes: 0,
        metadata: '',
      );

      final curriculum = courseViewModel.curriculum.value;
      if (curriculum != null &&
          curriculum.enrollmentId.isNotEmpty) {
        await courseViewModel.fetchCurriculum(
          curriculum.enrollmentId,
        );
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật tiến độ.');
    } finally {
      _isLogging = false;
    }
  }
}