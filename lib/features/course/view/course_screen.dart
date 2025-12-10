import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../course_progress/model/course_progress.dart';
import '../../course_progress/viewmodel/course_progress_viewmodel.dart';
import 'course_unit_screen.dart';

// --- Coursera/Enterprise Style Constants ---
const Color kCourseraBlue = Color(0xFF0056D2);
const Color kBackgroundColor = Colors.white;
const Color kTextPrimary = Color(0xFF1F1F1F);
const Color kTextSecondary = Color(0xFF5E5E5E);
const Color kCardBorderColor = Color(0xFFE0E0E0);
const double kCardRadius = 8.0;

// Chiều cao an toàn (Navbar 70 + Margin 16 + Buffer 30)
const double kBottomSafePadding = 120.0;

class CourseScreen extends StatefulWidget {
  final String? topic;
  const CourseScreen({super.key, this.topic});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final CourseProgressViewModel courseProgressViewModel =
  Get.find<CourseProgressViewModel>();

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
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Khóa học của tôi',
            style: TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: Obx(() {
        if (courseProgressViewModel.isLoading.value) {
          return const Center(
            child: CupertinoActivityIndicator(
              radius: 15,
              color: kCourseraBlue,
            ),
          );
        }

        if (courseProgressViewModel.courses.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await courseProgressViewModel.fetchMyCourses();
          },
          color: kCourseraBlue,
          backgroundColor: Colors.white,
          child: ListView.separated(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: kBottomSafePadding,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount:
            courseProgressViewModel.courses.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final course =
              courseProgressViewModel.courses[index];
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
        Get.to(
              () => CourseUnitScreen(
            courseId: course.courseId,
            courseTitle: course.courseTitle,
            enrollmentId: course.enrollmentId,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: kCardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  kCardRadius,
                ),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: _buildCourseImage(course),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      course.courseTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Teacher
                    Text(
                      course.teacherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kTextSecondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Progress bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value:
                              course.progressPercent /
                                  100,
                              minHeight: 6,
                              backgroundColor:
                              Colors.grey.shade200,
                              valueColor:
                              AlwaysStoppedAnimation(
                                course.progressPercent >=
                                    100
                                    ? Colors.green
                                    : kCourseraBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${course.progressPercent}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                            course.progressPercent >=
                                100
                                ? Colors.green
                                : kCourseraBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (course.level.isNotEmpty)
                          _buildTag(
                            course.level,
                            Colors.blue.shade50,
                            Colors.blue.shade700,
                          ),
                        _buildTag(
                          '${course.completedLessons}/${course.totalLessons} bài',
                          Colors.grey.shade100,
                          kTextSecondary,
                        ),
                        if (course.status.isNotEmpty)
                          _buildTag(
                            course.status,
                            course.status == 'Completed'
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            course.status == 'Completed'
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCourseImage(CourseProgress course) {
    if (course.courseImage.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey.shade400,
          size: 32,
        ),
      );
    }

    return Image.network(
      course.courseImage,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade50,
          child: const Center(
            child: CupertinoActivityIndicator(radius: 10),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade100,
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.grey.shade400,
            size: 32,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () =>
          courseProgressViewModel.fetchMyCourses(),
      child: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height:
              MediaQuery.of(context).size.height * 0.15,
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.book,
                size: 56,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có khóa học nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy đăng ký khóa học để bắt đầu hành trình học tập của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
