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
import 'pdf_view_screen.dart';

import '../model/course_exercise.dart';
import 'exercise_repeat_after_me_screen.dart';
import 'exercise_picture_description_screen.dart';
import 'exercise_debate_screen.dart';
import 'exercise_story_telling_screen.dart';
import 'exercise_submission_list_screen.dart';

enum LessonStep { content, video, document, exercise } // NEW

class CourseLessonScreen extends StatefulWidget {
  final String lessonId;
  const CourseLessonScreen({super.key, required this.lessonId});

  @override
  State<CourseLessonScreen> createState() => _CourseLessonScreenState();
}

class _CourseLessonScreenState extends State<CourseLessonScreen> {
  final ScrollController _scrollController = ScrollController(); // Thêm controller
  final CourseProgressViewModel progressViewModel = Get.find<CourseProgressViewModel>();
  final CourseViewModel courseViewModel = Get.find<CourseViewModel>();
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
    _lessonId = widget.lessonId;
    progressViewModel.fetchLessonProgressDetail(_lessonId);
  }

  @override
  void didUpdateWidget(covariant CourseLessonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonId != widget.lessonId) {
      _lessonId = widget.lessonId;
      _initedForLessonId = null; // NEW: reset để init lại cho bài mới
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

    // Chỉ thêm trạng thái cho step thực sự có
    _stepChecked = [];
    _loggedSteps.clear();
    for (final s in _availableSteps) {
      bool completed = switch (s) {
        LessonStep.content => activity.content.isCompleted,
        LessonStep.video => activity.video.isCompleted,
        LessonStep.document => activity.document.isCompleted,
        LessonStep.exercise => false, // exercise không có checkbox
      };
      _stepChecked.add(completed);
      if (completed && s != LessonStep.exercise) {
        _loggedSteps.add(s);
      }
    }

    // Prefetch bài tập và chèn step Exercise nếu có dữ liệu
    courseViewModel.fetchLessonExercises(detail.lessonId).then((_) {
      if (!mounted) return;
      if (courseViewModel.exercises.isNotEmpty &&
          !_availableSteps.contains(LessonStep.exercise)) {
        setState(() {
          _availableSteps.add(LessonStep.exercise);
          _stepChecked.add(false); // không tính vào checkbox
          if (_currentStep >= _availableSteps.length) {
            _currentStep = _availableSteps.length - 1;
          }
        });
      }
    });

    // NEW: Tìm step đầu tiên chưa hoàn thành và set _currentStep
    int firstIncompleteIndex = _stepChecked.indexWhere((checked) => !checked);
    if (firstIncompleteIndex != -1) {
      _currentStep = firstIncompleteIndex;
    } else {
      _currentStep = _availableSteps.length - 1; // Nếu tất cả hoàn thành, ở step cuối (thường là exercise)
    }

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
          setState(() {
            _lessonId = newLessonId;
            _currentStep = 0;
            _loggedSteps.clear();
            _availableSteps = [];
            _stepChecked = [];
            _initedForLessonId = null; // NEW
          });
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


        if (_initedForLessonId != detail.lessonId || _availableSteps.isEmpty || _stepChecked.isEmpty) {
          _initSteps(detail);
          _initedForLessonId = detail.lessonId;
        }

        return Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
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
    final isCompleted = _stepChecked.length > step && _stepChecked[step];

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
      ),
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
      case LessonStep.exercise:
        return _buildExerciseStep(detail.lessonId); // NEW
    }
  }

// NEW: danh sách bài tập nhúng ngay trong trang bài học
  Widget _buildExerciseStep(String lessonId) {
    return Obx(() {
      final loading = courseViewModel.isLoadingExercises.value;
      final list = courseViewModel.exercises;

      if (loading && list.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      if (list.isEmpty) {
        return _buildEmptyState(icon: Icons.assignment_outlined, message: 'Không có bài tập cho bài học này');
      }

      Color _difficultyColor(String diff) {
        switch (diff.toLowerCase()) {
          case 'easy': return Colors.green;
          case 'medium': return Colors.orange;
          case 'hard': return Colors.red;
          case 'advanced': return Colors.purple;
          default: return Colors.grey;
        }
      }


      Color _typeColor(String t) {
        switch (t) {
          case 'RepeatAfterMe': return Colors.blue;
          case 'PictureDescription': return Colors.green;
          case 'Debate': return Colors.orange;
          case 'StoryTelling': return Colors.purple;

          default: return AppColors.primary;
        }
      }

      String _typeLabel(String t) {
        switch (t) {
          case 'RepeatAfterMe': return 'Lặp lại theo mẫu';
          case 'PictureDescription': return 'Mô tả tranh';
          case 'Debate': return 'Tranh luận';
          case 'StoryTelling': return 'Kể chuyện';
          default: return 'Bài tập';
        }
      }

      void _openExercise(Exercise ex) {
        switch (ex.exerciseType) {
          case 'RepeatAfterMe':
            Get.to(() => ExerciseRepeatAfterMeScreen(exercise: ex));
            break;
          case 'PictureDescription':
            Get.to(() => ExerciseMultipleChoiceScreen(exercise: ex));
            break;
          case 'Debate':
            Get.to(() => ExerciseDebateScreen(exercise: ex));
            break;
          case 'StoryTelling':
            Get.to(() => ExerciseFillInBlankScreen(exercise: ex));
            break;
          default:
            Get.to(() => ExerciseRepeatAfterMeScreen(exercise: ex));
        }
      }

      void _viewScore(Exercise ex) {
        Get.to(() => ExerciseSubmissionListScreen(
          exerciseId: ex.exerciseID,
          exerciseTitle: ex.title,
        ));

      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bài tập', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final ex = list[i];
              final typeColor = _typeColor(ex.exerciseType); // Lấy màu cho loại bài tập
              return InkWell(
                onTap: () => _openExercise(ex),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(child: Text('${i + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ex.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(999)), // Áp dụng màu nền
                                      child: Text(_typeLabel(ex.exerciseType), style: TextStyle(fontSize: 12, color: typeColor, fontWeight: FontWeight.w600)), // Áp dụng màu chữ
                                    ),
                                    if (ex.difficulty.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _difficultyColor(ex.difficulty).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: _difficultyColor(ex.difficulty).withOpacity(0.5)),
                                        ),
                                        child: Text(ex.difficulty, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _difficultyColor(ex.difficulty))),
                                      ),
                                  ],
                                ),
                                if (ex.prompt.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(ex.prompt, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _viewScore(ex),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Xem điểm', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      );
    });
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
        SizedBox(
          width: double.infinity,
          child: Html(
            data: activity.content.resourceUrl ?? '',
            style: {
              'body': Style(margin: Margins.zero, padding: HtmlPaddings.zero), // Loại bỏ margin/padding mặc định
              'table': Style(width: Width(MediaQuery.of(context).size.width)), // Table full width
              'th, td': Style(padding: HtmlPaddings.all(8), border: Border.all(color: Colors.grey.shade300)), // Style cho table cells
            },
          ),
        ),
        const SizedBox(height: 16),
        if (idx >= 0)
          Row(
            children: [
              Checkbox(
                value: _stepChecked[idx],
                onChanged: _stepChecked[idx] ? null : (val) {
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
              onChanged: _stepChecked[idx] ? null : (val) {
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
                  final url = activity.document.resourceUrl;
                  if (url != null && url.isNotEmpty) {
                    Get.to(() => PdfViewScreen(pdfUrl: url, title: detail.lessonTitle));
                  } else {
                    Get.snackbar('Lỗi', 'Không tìm thấy tài liệu PDF');
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Xem tài liệu'),
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
              onChanged: _stepChecked[idx] ? null : (val) {
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
    // NEW: bỏ qua step Exercise khi tính hoàn thành
    final allCompleted = _stepChecked.isNotEmpty &&
        List.generate(_availableSteps.length, (i) => _availableSteps[i] == LessonStep.exercise ? true : _stepChecked[i]).every((c) => c);
    final isLastStep = _currentStep == _availableSteps.length - 1;

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
            if (_availableSteps.length > 1) const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () async {

                  if (!isLastStep) {
                    setState(() => _currentStep = (_currentStep + 1).clamp(0, _availableSteps.length - 1));
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

                  // NEW: không chuyển trang nữa ở bước cuối
                  Get.snackbar(
                    'Hoàn thành',
                    'Bạn đã hoàn thành bài học ${detail.lessonTitle}!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
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
                      isLastStep ? 'Hoàn thành' : 'Tiếp theo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastStep ? Icons.check : Icons.arrow_forward,
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
    // Nếu đã completed (từ server) hoặc đã log rồi ⇒ không làm lại
    if (_loggedSteps.contains(step) || _stepChecked[idx]) {
      setState(() { _stepChecked[idx] = true; });
      Get.snackbar('Thông báo', 'Mục này đã được hoàn thành.');
      return;
    }
    if (!checked) return;

    // Hiệu ứng UI ngay
    setState(() { _stepChecked[idx] = true; });

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
      if (curriculum != null && curriculum.enrollmentId.isNotEmpty) {
        await courseViewModel.fetchCurriculum(curriculum.enrollmentId);
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật tiến độ.');
    } finally {
      _isLogging = false;
    }
  }
}