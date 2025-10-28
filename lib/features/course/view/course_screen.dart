import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:get/get.dart';

import '../model/course.dart';
import '../viewmodel/course_viewmodel.dart';
import 'course_unit_screen.dart';

class CourseScreen extends StatefulWidget {
  final String? topic;
  const CourseScreen({super.key, this.topic});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final CourseViewModel courseViewModel = Get.put(CourseViewModel(Get.find()));
  final ScrollController _scrollController = ScrollController();
  bool _showPager = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      courseViewModel.fetchPage(1);
    });

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final currentOffset = _scrollController.offset;
      final maxScroll = _scrollController.position.maxScrollExtent;

      // Chỉ hiện pager khi scroll gần cuối (còn 200px) VÀ có thể scroll được
      final shouldShow = maxScroll > 0 && currentOffset >= maxScroll - 200;

      if (shouldShow != _showPager) {
        setState(() => _showPager = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.topic ?? "Khóa học",
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Obx(() {
        if (courseViewModel.isLoadingCourse.value && courseViewModel.courses.isEmpty) {
          return const Center(
            child: CupertinoActivityIndicator(radius: 15, color: AppColors.primary),
          );
        }

        final List<Course> filteredCourses = (widget.topic != null && widget.topic!.isNotEmpty)
            ? courseViewModel.courses.where((c) => c.topics.contains(widget.topic)).toList()
            : courseViewModel.courses.toList();

        if (filteredCourses.isEmpty) return _buildEmptyState();

        return RefreshIndicator(
          onRefresh: () => courseViewModel.fetchPage(1),
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: filteredCourses.length,
                itemBuilder: (context, index) {
                  final course = filteredCourses[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildCourseCard(course),
                  );
                },
              ),

              // THANH PAGING
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: _showPager ? Offset.zero : const Offset(0, 1),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showPager ? 1.0 : 0.0,
                    child: _buildPager(),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPager() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(() => Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: courseViewModel.hasPrevPage.value
                      ? () => courseViewModel.prevPage()
                      : null,
                  icon: const Icon(CupertinoIcons.chevron_left, size: 18),
                  label: const Text('Trước'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Trang ${courseViewModel.currentPage.value}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: courseViewModel.hasNextPage.value
                      ? () => courseViewModel.nextPage()
                      : null,
                  label: const Text('Sau'),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(CupertinoIcons.chevron_right, size: 18),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => courseViewModel.fetchPage(1),
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(CupertinoIcons.book, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'Không có khóa học nào',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chúng tôi sẽ sớm cập nhật thêm các khóa học mới.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return GestureDetector(
      onTap: () {
        Get.to(
              () => CourseUnitScreen(courseId: course.courseID, courseTitle: course.title),
          transition: Transition.cupertino,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourseImage(course),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseType(course),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  _buildCardFooter(course),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseImage(Course course) {
    if (course.imageUrl.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 40),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          course.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CupertinoActivityIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 40),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCourseType(Course course) {
    final bool isFree = course.courseType == "Free";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isFree ? AppColors.success : AppColors.warning).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isFree ? "Miễn phí" : "Trả phí",
        style: TextStyle(color: isFree ? AppColors.success : AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCardFooter(Course course) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(CupertinoIcons.person_alt_circle, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  course.teacherName,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            Icon(CupertinoIcons.book, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              '${course.numLessons} bài học',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}