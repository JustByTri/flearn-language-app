import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';

import '../model/course.dart';
import '../viewmodel/course_viewmodel.dart';
import 'course_detail_screen.dart';

class BrowseCourseScreen extends StatefulWidget {
  final String? searchQuery;
  final String? topic;
  final String? sortBy;
  final String? programId;

  const BrowseCourseScreen({
    super.key,
    this.searchQuery,
    this.topic,
    this.sortBy,
    this.programId,
  });

  @override
  State<BrowseCourseScreen> createState() => _BrowseCourseScreenState();
}

class _BrowseCourseScreenState extends State<BrowseCourseScreen> {
  final CourseViewModel courseViewModel = Get.find<CourseViewModel>();
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();

  // Local state to prevent data loss
  final RxList<Course> _localCourses = <Course>[].obs;
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery ?? '';
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _getCurrentLanguageCode() async {
    try {
      final box = GetStorage();
      final user = box.read('user');

      if (user != null && user['languageId'] != null) {
        final String languageId = user['languageId'];

        // Fetch languages to get langCode
        final response = await _dio.get('https://f-learn.app/api/languages');
        if (response.statusCode == 200 && response.data['status'] == 'success') {
          List<dynamic> languages = response.data['data'];
          final language = languages.firstWhere(
            (lang) => lang['id'] == languageId,
            orElse: () => null,
          );

          if (language != null) {
            return language['langCode'] as String?;
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting language code: $e');
    }
    return null;
  }

  Future<void> _loadCourses() async {
    try {
      _isLoading.value = true;

      // Get language code
      final langCode = await _getCurrentLanguageCode();

      debugPrint('BrowseCourseScreen: Loading courses with langCode: $langCode, search: ${widget.searchQuery}, sortBy: ${widget.sortBy}');

      // Fetch courses but store in local state
      await courseViewModel.fetchCoursesWithLanguage(
        lang: langCode,
        searchTerm: widget.searchQuery,
        sortBy: widget.sortBy,
        isRefresh: true,
      );

      // Copy to local state to prevent loss
      _localCourses.value = List.from(courseViewModel.courses);

      debugPrint('BrowseCourseScreen: Loaded ${_localCourses.length} courses');
    } catch (e) {
      debugPrint('BrowseCourseScreen: Error loading courses: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  String _getTitle() {
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      return 'Kết quả tìm kiếm';
    }
    if (widget.topic != null) {
      return widget.topic!;
    }
    return 'Khám phá khóa học';
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
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (value) async {
                      if (value.trim().isNotEmpty) {
                        // Navigate to new search results
                        Get.off(
                          () => BrowseCourseScreen(
                            searchQuery: value.trim(),
                            topic: widget.topic,
                            sortBy: widget.sortBy,
                            programId: widget.programId,
                          ),
                        );
                      } else {
                        // Clear search and reload
                        _searchController.clear();
                        setState(() {});
                        await _loadCourses();
                      }
                    },
                    decoration: InputDecoration(
                      icon: const Icon(CupertinoIcons.search, color: Colors.grey),
                      border: InputBorder.none,
                      hintText: 'Tìm kiếm khóa học...',
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                _loadCourses();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {}); // Update UI for clear button
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Courses list
                Obx(() {
                  // Use local loading state
                  if (_isLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50.0),
                        child: CupertinoActivityIndicator(),
                      ),
                    );
                  }

                  // Use local courses to prevent data loss
                  var courses = _localCourses;

                  // Filter by topic if specified
                  if (widget.topic != null && widget.topic!.isNotEmpty) {
                    courses = courses.where((course) {
                      return course.topics.any((topic) => topic.topicName == widget.topic);
                    }).toList().obs;
                  }

                  // Filter by program if specified
                  if (widget.programId != null && widget.programId!.isNotEmpty) {
                    courses = courses.where((course) {
                      return course.program?.programId == widget.programId;
                    }).toList().obs;
                  }

                  if (courses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(50.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy khóa học',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                                  ? 'Thử tìm kiếm với từ khóa khác'
                                  : 'Chưa có khóa học nào phù hợp với bộ lọc',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tìm thấy ${courses.length} khóa học',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: courses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return _CourseCard(course: course);
                        },
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;

  const _CourseCard({required this.course});

  String formatVND(int price) {
    if (price == 0) return 'Miễn phí';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => CourseDetailScreen(courseId: course.courseID));
      },
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                (course.imageUrl.isNotEmpty)
                    ? Image.network(
                        course.imageUrl,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.school, color: Colors.grey, size: 60),
                      ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: course.courseType == 'Free'
                          ? Colors.green.shade400
                          : Colors.orange.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formatVND(course.price),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.program?.name ?? 'Chương trình',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${course.averageRating}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.person_outline, color: Colors.grey.shade600, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${course.learnerCount} học viên',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
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
}

