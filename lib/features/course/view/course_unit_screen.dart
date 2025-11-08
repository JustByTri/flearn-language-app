import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/fadeSlideAnimation.dart';
import '../model/course_unit.dart';
import '../viewmodel/course_viewmodel.dart';
import 'course_lesson_screen.dart';

class CourseUnitScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  const CourseUnitScreen({super.key, required this.courseId, required this.courseTitle});

  @override
  State<CourseUnitScreen> createState() => _CourseUnitScreenState();
}

class _CourseUnitScreenState extends State<CourseUnitScreen> {
  late final CourseViewModel courseViewModel;
  final Set<String> _expandedUnits = {};

  @override
  void initState() {
    super.initState();
    courseViewModel = Get.find<CourseViewModel>();
    courseViewModel.fetchCourseUnits(widget.courseId);
  }

  void _toggleUnit(String unitId) {
    setState(() {
      if (_expandedUnits.contains(unitId)) {
        _expandedUnits.remove(unitId);
      } else {
        _expandedUnits.add(unitId);
        // Fetch lessons when expanding
        courseViewModel.fetchCourseLessons(unitId);
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
        if (courseViewModel.isLoadingUnit.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final units = courseViewModel.units;
        if (units.isEmpty) {
          return _buildEmptyState();
        }
        return FadeSlideAnimation(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: units.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final unit = units[index];
              final isExpanded = _expandedUnits.contains(unit.courseUnitID);
              return _buildUnitCard(unit, index, isExpanded);
            },
          ),
        );
      }),
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
            Obx(() {
              if (courseViewModel.isLoadingLesson.value) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }
              final lessons = courseViewModel.lessons;
              if (lessons.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Chưa có bài học nào', style: TextStyle(color: Colors.grey.shade600)),
                );
              }
              return Column(
                children: lessons.map((lesson) => _buildLessonTile(lesson)).toList(),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonTile(dynamic lesson) {
    return InkWell(
      onTap: () async {
        final courseViewModel = Get.find<CourseViewModel>();
        final lessonDetail = await courseViewModel.fetchLessonById(lesson.lessonID);
        if (lessonDetail != null) {
          Get.to(() => CourseLessonScreen(
            lesson: lessonDetail,
          ));
        } else {
          Get.snackbar('Lỗi', 'Không thể tải bài học');
        }
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
}