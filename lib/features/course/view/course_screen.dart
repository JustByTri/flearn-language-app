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
  final CourseViewModel courseViewModel = Get.find<CourseViewModel>();
  late final ScrollController _scrollController;
  bool _localLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      courseViewModel.fetchMoreCourses(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!mounted) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = MediaQuery.of(context).size.height * 0.2;

    if (currentScroll > maxScroll - threshold) {
      if (courseViewModel.hasMoreCourses.value &&
          !courseViewModel.isLoadingCourse.value &&
          !_localLoading) {
        _startFetchMore();
      }
    }
  }

  Future<void> _startFetchMore() async {
    if (!mounted || _localLoading || courseViewModel.isLoadingCourse.value) return;
    setState(() => _localLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      await courseViewModel.fetchMoreCourses();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _localLoading = false);
      }
    }
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
          'Các khóa học',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar only
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: widget.topic ?? 'Programming',
                  hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFBBBBBB), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
          // Course list
          Expanded(
            child: Obx(() {
              if (courseViewModel.isLoadingCourse.value && courseViewModel.courses.isEmpty) {
                return const Center(
                  child: CupertinoActivityIndicator(radius: 15, color: AppColors.primary),
                );
              }

              final List<Course> filteredCourses = (widget.topic != null && widget.topic!.isNotEmpty)
                  ? courseViewModel.courses.where((c) => c.topics.contains(widget.topic)).toList()
                  : courseViewModel.courses.toList();

              if (filteredCourses.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _localLoading = false;
                  await courseViewModel.fetchMoreCourses(isRefresh: true);
                },
                color: AppColors.primary,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filteredCourses.length +
                      (courseViewModel.isLoadingCourse.value || _localLoading ? 1 : 0) +
                      (!courseViewModel.isLoadingCourse.value && !courseViewModel.hasMoreCourses.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= filteredCourses.length) {
                      if (courseViewModel.isLoadingCourse.value || _localLoading) {
                        return _buildInlineLoading();
                      }
                      if (!courseViewModel.hasMoreCourses.value) {
                        return _buildEndOfList();
                      }
                      return const SizedBox.shrink();
                    }

                    final course = filteredCourses[index];
                    return _buildCourseCard(course);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.25;

    return GestureDetector(
      onTap: () {
        Get.to(
              () => CourseUnitScreen(courseId: course.courseID, courseTitle: course.title),
          transition: Transition.cupertino,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildCourseImageSmall(course, imageSize),
            ),
            const SizedBox(width: 14),
            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Info rows
                  _buildInfoRow(CupertinoIcons.play_circle, '${course.numLessons}+ Lessons'),
                  const SizedBox(height: 4),
                  _buildInfoRow(CupertinoIcons.time, '115+ Hours'),
                  const SizedBox(height: 10),
                  // Avatar + See Details
                  Row(
                    children: [
                      _buildAvatarStack(),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Get.to(
                                () => CourseUnitScreen(
                              courseId: course.courseID,
                              courseTitle: course.title,
                            ),
                            transition: Transition.cupertino,
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'See Details',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 24,
          child: Stack(
            children: [
              Positioned(left: 0, child: _buildAvatar(0)),
              Positioned(left: 18, child: _buildAvatar(1)),
              Positioned(left: 36, child: _buildAvatar(2)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          '69k+ Joined',
          style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
        ),
      ],
    );
  }

  Widget _buildAvatar(int index) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade300,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: Icon(Icons.person, size: 14, color: Colors.grey.shade500),
      ),
    );
  }

  Widget _buildCourseImageSmall(Course course, double size) {
    if (course.imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.image, color: Colors.grey.shade400, size: size * 0.4),
      );
    }

    return Image.network(
      course.imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: CupertinoActivityIndicator(radius: 10)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: size * 0.4),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF999999)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildInlineLoading() {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        bottom: 100 + MediaQuery.of(context).padding.bottom,
      ),
      child: const Center(
        child: CupertinoActivityIndicator(radius: 14),
      ),
    );
  }

  Widget _buildEndOfList() {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        bottom: 100 + MediaQuery.of(context).padding.bottom,
      ),
      child: const Center(
        child: Text(
          'Bạn đã xem hết tất cả các khóa học',
          style: TextStyle(color: Color(0xFF999999), fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => courseViewModel.fetchPage(1),
      child: Center(
        child: ListView(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(CupertinoIcons.book, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'Không có khóa học nào',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chúng tôi sẽ sớm cập nhật thêm các khóa học mới.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }
}