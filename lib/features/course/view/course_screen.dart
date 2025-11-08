import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:get/get.dart';

import '../model/course.dart';
import '../viewmodel/course_viewmodel.dart';
import 'course_detail_screen.dart';
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

  String _formatPrice(int price) {
    if (price >= 1000000) {
      double millions = price / 1000000;
      if (millions % 1 == 0) {
        return '${millions.toInt()}tr';
      }
      return '${millions.toStringAsFixed(1)}tr';
    } else if (price >= 1000) {
      double thousands = price / 1000;
      if (thousands % 1 == 0) {
        return '${thousands.toInt()}k';
      }
      return '${thousands.toStringAsFixed(1)}k';
    }
    return '${price}đ';
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
          // Search bar
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
                  ? courseViewModel.courses.where((c) => c.topics.any((t) => t.topicName.contains(widget.topic!))).toList()
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
    return GestureDetector(
      onTap: () async {
        final vm = Get.find<CourseViewModel>();
        await vm.fetchCourseDetail(course.courseID);
        Get.to(() => CourseDetailScreen(courseId: course.courseID));
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
                      course.title,
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

                    // Teacher + rating
                    Row(
                      children: [
                        if (course.teacher != null) ...[
                          Flexible(
                            child: Text(
                              course.teacher!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        const Icon(Icons.star, size: 14, color: Color(0xFFFFB800)),
                        const SizedBox(width: 3),
                        Text(
                          course.averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Text('${course.learnerCount}+', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Small chips: level / lessons / days
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (course.program?.level?.name != null && course.program!.level!.name.isNotEmpty)
                          _buildTag(course.program!.level!.name),
                        _buildTag('${course.numLessons} lessons'),
                        _buildTag('${course.durationDays} days'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(course.discountPrice ?? course.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  if (course.discountPrice != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatPrice(course.price),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFAAAAAA),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
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
          '1k+ Enrolled',
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

  Widget _buildCourseImage(Course course) {
    if (course.imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: 180,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
        ),
        child: Icon(Icons.image, color: Colors.grey.shade400, size: 60),
      );
    }

    return Image.network(
      course.imageUrl,
      width: double.infinity,
      height: 180,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: 180,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
          ),
          child: const Center(child: CupertinoActivityIndicator(radius: 15)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 180,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
          ),
          child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 60),
        );
      },
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