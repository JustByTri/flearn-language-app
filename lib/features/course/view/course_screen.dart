import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:get/get.dart';

import '../../course_progress/viewmodel/course_progress_viewmodel.dart';
import '../../course_progress/model/course_progress.dart';
import 'course_unit_screen.dart';

class CourseScreen extends StatefulWidget {
  final String? topic;
  const CourseScreen({super.key, this.topic});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final CourseProgressViewModel courseProgressViewModel = Get.find<CourseProgressViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      courseProgressViewModel.fetchMyCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF1A1A1A)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Khóa học của tôi',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Obx(() {
        if (courseProgressViewModel.isLoading.value) {
          return const Center(
            child: CupertinoActivityIndicator(radius: 15, color: AppColors.primary),
          );
        }

        if (courseProgressViewModel.courses.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await courseProgressViewModel.fetchMyCourses();
          },
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: courseProgressViewModel.courses.length,
            itemBuilder: (context, index) {
              final course = courseProgressViewModel.courses[index];
              return _buildCourseCard(course);
            },
          ),
        );
      }),
    );
  }

  Widget _buildCourseCard(CourseProgress course) {
    return GestureDetector(
      onTap: () {
        Get.to(() => CourseUnitScreen(
          courseId: course.courseId,
          courseTitle: course.courseTitle,
          enrollmentId: course.enrollmentId,
        ));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _buildCourseImage(course),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      course.courseTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Teacher
                    Text(
                      course.teacherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                    ),

                    const SizedBox(height: 6),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: course.progressPercent / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          course.progressPercent >= 100 ? Colors.green : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),


                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildTag(course.level),
                        _buildTag('${course.completedLessons}/${course.totalLessons} bài'),
                        _buildTag(course.status),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Progress percent
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${course.progressPercent}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.language,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF666666),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCourseImage(CourseProgress course) {
    if (course.courseImage.isEmpty) {
      return Container(
        width: double.infinity,
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
        ),
        child: Icon(Icons.image, color: Colors.grey.shade400, size: 40),
      );
    }

    return Image.network(
      course.courseImage,
      width: double.infinity,
      height: 80,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
          ),
          child: const Center(child: CupertinoActivityIndicator(radius: 12)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
          ),
          child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 40),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => courseProgressViewModel.fetchMyCourses(),
      child: Center(
        child: ListView(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(CupertinoIcons.book, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'Bạn chưa có khóa học nào',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy đăng ký khóa học để bắt đầu học tập.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }
}