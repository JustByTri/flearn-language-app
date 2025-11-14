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

  // ===== NEW: local filters giống Home =====
  String? _currentSortBy;
  String? _selectedTopicName;
  String? _selectedProgramId;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery ?? '';
    // init local filters từ params ban đầu
    _currentSortBy = widget.sortBy;
    _selectedTopicName = widget.topic;
    _selectedProgramId = widget.programId;
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

      debugPrint('BrowseCourseScreen: Loading courses with langCode: $langCode, search: ${widget.searchQuery}, sortBy: ${_currentSortBy}');

      // Fetch courses but store in local state
      await courseViewModel.fetchCoursesWithLanguage(
        lang: langCode,
        searchTerm: widget.searchQuery,
        sortBy: _currentSortBy, // dùng sort hiện tại
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

  // ===== NEW: tiện ích build danh sách chương trình & chủ đề từ courses hiện có =====
  List<Map<String, String>> _derivePrograms() {
    final map = <String, String>{};
    for (final c in _localCourses) {
      final id = c.program?.programId;
      final name = c.program?.name;
      if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
        map[id] = name;
      }
    }
    return map.entries.map((e) => {'id': e.key, 'name': e.value}).toList();
  }

  List<String> _deriveTopics() {
    final set = <String>{};
    for (final c in _localCourses) {
      for (final t in c.topics) {
        if (t.topicName.isNotEmpty) set.add(t.topicName);
      }
    }
    return set.toList()..sort();
  }

  // ===== NEW: bottom sheet filter giống Home =====
  void _showFilterBottomSheet() {
    String? tempSelectedProgram = _selectedProgramId;
    String? tempSelectedTopic = _selectedTopicName;
    String? tempSortBy = _currentSortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final programs = _derivePrograms();
        final topics = _deriveTopics();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Lọc khóa học', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Programs
                        const Text('Chọn chương trình', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Tất cả chương trình'),
                              selected: tempSelectedProgram == null,
                              onSelected: (_) => setModalState(() => tempSelectedProgram = null),
                            ),
                            ...programs.map((p) {
                              final selected = tempSelectedProgram == p['id'];
                              return ChoiceChip(
                                label: Text(p['name'] ?? ''),
                                selected: selected,
                                onSelected: (_) => setModalState(() => tempSelectedProgram = p['id']),
                              );
                            }),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Topics
                        const Text('Chọn chủ đề', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Tất cả'),
                              selected: tempSelectedTopic == null,
                              onSelected: (_) => setModalState(() => tempSelectedTopic = null),
                            ),
                            ...topics.map((name) {
                              final selected = tempSelectedTopic == name;
                              return ChoiceChip(
                                label: Text(name),
                                selected: selected,
                                onSelected: (_) => setModalState(() => tempSelectedTopic = name),
                              );
                            }),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Sort
                        const Text('Sắp xếp theo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: tempSortBy,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Mặc định')),
                            DropdownMenuItem(value: 'newest', child: Text('Mới nhất')),
                            DropdownMenuItem(value: 'oldest', child: Text('Cũ nhất')),
                            DropdownMenuItem(value: 'price_asc', child: Text('Giá: Thấp đến Cao')),
                            DropdownMenuItem(value: 'price_desc', child: Text('Giá: Cao đến Thấp')),
                            DropdownMenuItem(value: 'rating_desc', child: Text('Đánh giá: Cao nhất')),
                            DropdownMenuItem(value: 'rating_asc', child: Text('Đánh giá: Thấp nhất')),
                            DropdownMenuItem(value: 'learners_desc', child: Text('Học viên: Nhiều nhất')),
                          ],
                          onChanged: (v) => setModalState(() => tempSortBy = v),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Actions
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              setState(() {
                                _selectedProgramId = tempSelectedProgram;
                                _selectedTopicName = tempSelectedTopic;
                                _currentSortBy = tempSortBy;
                              });
                              await _loadCourses();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Áp dụng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempSelectedProgram = null;
                                tempSelectedTopic = null;
                                tempSortBy = null;
                              });
                            },
                            child: const Text('Đặt lại', style: TextStyle(fontSize: 16, color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
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
                // ===== UPDATED: Search + Filter button giống Home =====
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                              Get.off(() => BrowseCourseScreen(
                                searchQuery: value.trim(),
                                topic: _selectedTopicName,
                                sortBy: _currentSortBy,
                                programId: _selectedProgramId,
                              ));
                            } else {
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
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(255),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _showFilterBottomSheet,
                        icon: const Icon(CupertinoIcons.slider_horizontal_3, color: Colors.white, size: 24),
                        padding: EdgeInsets.zero,
                        tooltip: 'Lọc khóa học',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Courses list
                Obx(() {
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

                  // Filter by topic if specified (state)
                  if (_selectedTopicName != null && _selectedTopicName!.isNotEmpty) {
                    courses = courses.where((course) {
                      return course.topics.any((topic) => topic.topicName == _selectedTopicName);
                    }).toList().obs;
                  }

                  // Filter by program if specified (state)
                  if (_selectedProgramId != null && _selectedProgramId!.isNotEmpty) {
                    courses = courses.where((course) {
                      return course.program?.programId == _selectedProgramId;
                    }).toList().obs;
                  }

                  if (courses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(50.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Không tìm thấy khóa học',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Thử tìm kiếm với từ khóa khác'
                                  : 'Chưa có khóa học nào phù hợp với bộ lọc',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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

