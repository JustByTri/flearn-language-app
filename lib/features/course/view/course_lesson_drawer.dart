import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../viewmodel/course_viewmodel.dart';
import 'course_lesson_screen.dart';

class CourseLessonDrawer extends StatelessWidget {
  final String currentLessonId;
  // NEW: callback chọn bài
  final ValueChanged<String>? onLessonSelected;

  const CourseLessonDrawer({
    super.key,
    required this.currentLessonId,
    this.onLessonSelected,
  });

  @override
  Widget build(BuildContext context) {
    final courseViewModel = Get.find<CourseViewModel>();
    final curriculum = courseViewModel.curriculum.value;
    if (curriculum == null) {
      return Drawer(
        child: Center(child: Text('Không có dữ liệu chương/bài học')),
      );
    }
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1)),
              child: Text(
                curriculum.courseTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            ...curriculum.units.map((unit) => ExpansionTile(
              title: Text(unit.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              initiallyExpanded: unit.lessons.any((l) => l.lessonId == currentLessonId),
              children: unit.lessons.map((lesson) {
                final isCurrent = lesson.lessonId == currentLessonId;
                return ListTile(
                  title: Text(
                    lesson.title,
                    style: TextStyle(
                      color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  leading: isCurrent ? const Icon(Icons.play_arrow, color: AppColors.primary) : null,
                  onTap: () {
                    Navigator.of(context).pop(); // đóng Drawer trước
                    // gọi callback sau khi Drawer đóng hẳn
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (!isCurrent) {
                        onLessonSelected?.call(lesson.lessonId);
                      }
                    });
                  },
                );
              }).toList(),
            )),
          ],
        ),
      ),
    );
  }
}