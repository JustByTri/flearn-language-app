import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/fadeSlideAnimation.dart';
import '../model/course_unit.dart';
import '../model/curriculum.dart';
import '../viewmodel/course_viewmodel.dart';
import 'course_detail_screen.dart';
import 'course_lesson_screen.dart';

class CourseUnitScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String? enrollmentId;
  const CourseUnitScreen({super.key, required this.courseId, required this.courseTitle, this.enrollmentId});

  @override
  State<CourseUnitScreen> createState() => _CourseUnitScreenState();
}

class _CourseUnitScreenState extends State<CourseUnitScreen> {
  late final CourseViewModel courseViewModel;
  final Set<String> _expandedUnits = {};
  final Map<String, List<dynamic>> _unitLessons = {};
  final Map<String, bool> _unitLoading = {};

  @override
  void initState() {
    super.initState();
    courseViewModel = Get.find<CourseViewModel>();
    // Tránh cập nhật Obx trong quá trình build -> gọi sau khi frame hiện tại hoàn tất
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.enrollmentId != null && widget.enrollmentId!.isNotEmpty) {
        courseViewModel.fetchCurriculum(widget.enrollmentId!);
      } else {
        courseViewModel.fetchCourseUnits(widget.courseId);
      }
    });
  }

  Future<void> _fetchLessonsForUnit(String unitId) async {
    setState(() {
      _unitLoading[unitId] = true;
    });
    await courseViewModel.fetchCourseLessons(unitId);
    setState(() {
      _unitLessons[unitId] = courseViewModel.lessons.toList();
      _unitLoading[unitId] = false;
    });
  }

  void _toggleUnit(String unitId) {
    setState(() {
      if (_expandedUnits.contains(unitId)) {
        _expandedUnits.remove(unitId);
      } else {
        _expandedUnits.add(unitId);
        if (!_unitLessons.containsKey(unitId)) {
          _fetchLessonsForUnit(unitId);
        }
      }
    });
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
          widget.courseTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final useCurriculum = widget.enrollmentId != null && widget.enrollmentId!.isNotEmpty;
        if (useCurriculum) {
          if (courseViewModel.isLoadingCurriculum.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final data = courseViewModel.curriculum.value;
          final error = courseViewModel.curriculumError.value;
          if (data == null) {
            if (error != null) {
              return _buildErrorState(error); // Hiển thị error message
            }
            return _buildEmptyState();
          }
          final units = data.units;
          if (units.isEmpty) return _buildEmptyState();

          return RefreshIndicator(
            onRefresh: () async {
              await courseViewModel.fetchCurriculum(widget.enrollmentId!);
            },
            child: FadeSlideAnimation(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: units.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final u = units[i];
                  final expanded = _expandedUnits.contains(u.unitId);
                  return _buildCurriculumUnitCard(u, expanded);
                },
              ),
            ),
          );
        }
        // fallback cũ
        if (courseViewModel.isLoadingUnit.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final units = courseViewModel.units;
        if (units.isEmpty) return _buildEmptyState();
        return FadeSlideAnimation(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: units.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final unit = units[i];
              final expanded = _expandedUnits.contains(unit.courseUnitID);
              return _buildUnitCard(unit, i, expanded);
            },
          ),
        );
      }),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    String cleanMessage = errorMessage.replaceFirst('Exception: ', '');

    String translatedMessage = cleanMessage;
    if (cleanMessage == "Enrollment has been cancelled or expired. Access to course curriculum is denied.") {
      translatedMessage = "Đăng ký khóa học đã bị hủy hoặc hết hạn. Quyền truy cập vào chương trình học bị từ chối.";
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            translatedMessage,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.to(() => CourseDetailScreen(courseId: widget.courseId, showTeacherProfile: true)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Bạn cần đăng ký học lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Chưa có chương nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Khóa học này hiện chưa có nội dung', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildUnitCard(CourseUnit unit, int index, bool isExpanded) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleUnit(unit.courseUnitID),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${unit.position}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${unit.totalLessons} bài học',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Builder(
              builder: (context) {
                final loading = _unitLoading[unit.courseUnitID] ?? false;
                final lessons = _unitLessons[unit.courseUnitID] ?? [];
                if (loading) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }
                if (lessons.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Chưa có bài học nào', style: TextStyle(color: Colors.grey.shade600)),
                  );
                }
                return Column(
                  children: lessons.map((lesson) => _buildLessonTile(lesson)).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonTile(dynamic lesson) {
    return InkWell(
      onTap: () {

        Get.to(() => CourseLessonScreen(
          lessonId: lesson.lessonID,
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.play_circle_outline, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                lesson.title,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (lesson.status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lesson.status.toString().toLowerCase() == 'inprogress'
                      ? 'Tiếp tục'
                      : (lesson.status.toString().toLowerCase() == 'notstarted'
                      ? 'Bắt đầu'
                      : 'Hoàn thành'),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Bắt đầu',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'inprogress':
      case 'in_progress':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCurriculumUnitCard(CurriculumUnit unit, bool isExpanded) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isExpanded ? _expandedUnits.remove(unit.unitId) : _expandedUnits.add(unit.unitId);
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${unit.order}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (unit.progressPercent.clamp(0, 100)) / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              unit.progressPercent >= 100 ? Colors.green : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(unit.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unit.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(unit.status),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${unit.progressPercent.toInt()}%',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Column(

              children: unit.lessons.map((l) => _buildCurriculumLessonTile(l, unit.unitId)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurriculumLessonTile(CurriculumLesson lesson, String unitId) {
    return InkWell(
      onTap: () async {
        final vm = Get.find<CourseViewModel>();

        if (lesson.status.toLowerCase() == 'notstarted') {
          Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
          try {
            await vm.startLesson(unitId: unitId, lessonId: lesson.lessonId);

            if (widget.enrollmentId != null && widget.enrollmentId!.isNotEmpty) {
              await vm.fetchCurriculum(widget.enrollmentId!);
            }
          } catch (e) {
            Get.snackbar('Lỗi', 'Không thể bắt đầu bài học');
          } finally {
            if (Get.isDialogOpen ?? false) Get.back();
          }
        }

        Get.to(() => CourseLessonScreen(
          lessonId: lesson.lessonId,
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.play_circle_outline, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (lesson.progressPercent.clamp(0, 100)) / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        lesson.progressPercent >= 100 ? Colors.green : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            Text(
              '${lesson.progressPercent.toInt()}%',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                lesson.status.toLowerCase() == 'inprogress'
                    ? 'Tiếp tục'
                    : (lesson.status.toLowerCase() == 'notstarted'
                    ? 'Bắt đầu'
                    : 'Hoàn thành'),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}