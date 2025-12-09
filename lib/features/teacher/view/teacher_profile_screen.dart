import 'package:cached_network_image/cached_network_image.dart';
import 'package:flearn_app/features/course/view/course_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/teacher_profile_model.dart';
import '../viewmodel/teacher_viewmodel.dart';

class TeacherProfileScreen extends StatefulWidget {
  final String teacherId;

  const TeacherProfileScreen({super.key, required this.teacherId});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final TeacherViewModel _viewModel = Get.find();

  @override
  void initState() {
    super.initState();
    _viewModel.fetchTeacherProfile(widget.teacherId);
    _viewModel.fetchTeacherReviews(widget.teacherId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ giảng viên'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: Obx(() {
        if (_viewModel.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = _viewModel.teacherProfile.value;
        if (profile == null) {
          return const Center(child: Text('Không tải được hồ sơ giảng viên.'));
        }

        return DefaultTabController(
          length: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(profile),
                const SizedBox(height: 24),
                _buildStats(profile),
                const SizedBox(height: 24),
                const TabBar(
                  tabs: [
                    Tab(text: 'Khoá học'),
                    Tab(text: 'Đánh giá'),
                  ],
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.deepPurple,
                ),
                SizedBox(
                  height: 400, // Tăng chiều cao để hiển thị nhiều khóa học hơn
                  child: TabBarView(
                    children: [
                      _buildCoursesTab(profile.publishedCourses),
                      _buildReviewsTab(profile),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(TeacherProfile profile) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: CachedNetworkImageProvider(profile.avatar),
        ),
        const SizedBox(height: 16),
        Text(
          profile.fullName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          profile.bio,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStats(TeacherProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Khoá học', profile.totalCourses.toString()),
        _buildStatItem('Học viên', profile.totalStudents.toString()),
        _buildStatItem('Đánh giá', profile.totalReviews.toString()),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCoursesTab(List<PublishedCourse> courses) {
    if (courses.isEmpty) {
      return const Center(child: Text('Chưa có khoá học nào được xuất bản.'));
    }
    return ListView.builder(
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: course.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                const Icon(Icons.error),
              ),
            ),
            title: Text(
              course.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${course.averageRating} (${course.reviewCount} đánh giá)'),
              ],
            ),
            onTap: () {
              // Chuyển sang CourseDetailScreen bằng Get.to để push lên stack, không dùng Get.off
              Get.to(() => CourseDetailScreen(courseId: course.courseId, showTeacherProfile: false), routeName: '/courseDetailFromProfile');
            },
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(TeacherProfile profile) {
    final vm = _viewModel;
    bool _isShowingReviewForm = false;
    final TextEditingController _reviewController = TextEditingController();
    int _reviewRating = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        final submitting = vm.isSubmittingReview.value;

        Widget _buildReviewForm() {
          return Card(
            margin: const EdgeInsets.all(0),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.rate_review, color: Colors.deepPurple, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Đánh giá giáo viên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _isShowingReviewForm = false),
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.grey.shade600,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Đánh giá của bạn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < _reviewRating;
                      return GestureDetector(
                        onTap: submitting ? null : () => setState(() => _reviewRating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: filled ? const Color(0xFFFFB800) : Colors.grey.shade400,
                            size: 28,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  const Text('Nhận xét của bạn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reviewController,
                    enabled: !submitting,
                    decoration: InputDecoration(
                      hintText: 'Chia sẻ trải nghiệm của bạn về giáo viên này...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(color: Colors.deepPurple, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(12),
                      isDense: true,
                    ),
                    minLines: 3,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                        if (_reviewRating == 0) {
                          Get.snackbar('Thiếu thông tin', 'Vui lòng chọn số sao đánh giá.');
                          return;
                        }
                        final comment = _reviewController.text.trim();
                        final res = await vm.submitTeacherReview(
                          teacherId: profile.teacherId,
                          rating: _reviewRating,
                          comment: comment.isEmpty ? ' ' : comment,
                        );
                        final status = res?['status']?.toString().toLowerCase();
                        final code = res?['code'] as int? ?? -1;
                        final msg = (res?['message'] ?? '').toString();

                        if (status == 'success' && code >= 200 && code < 300) {
                          setState(() {
                            _isShowingReviewForm = false;
                            _reviewRating = 0;
                          });
                          _reviewController.clear();
                          vm.fetchTeacherProfile(profile.teacherId);
                          vm.fetchTeacherReviews(profile.teacherId);
                          Get.snackbar('Cảm ơn', 'Cảm ơn bạn đã đánh giá!');
                        } else if (msg.contains('không phù hợp') || msg.contains('vi phạm')) {
                          Get.snackbar('Bị từ chối', msg);
                        } else if (msg.toLowerCase().contains('already reviewed')) {
                          setState(() => _isShowingReviewForm = false);
                          vm.fetchTeacherReviews(profile.teacherId);
                          Get.snackbar('Thông báo', 'Bạn đã gửi đánh giá giáo viên này rồi');
                        } else {
                          Get.snackbar('Lỗi', msg.isNotEmpty ? msg : 'Không gửi được đánh giá. Vui lòng thử lại.');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: submitting
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 8),
                          Text('Đang gửi...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 16),
                          SizedBox(width: 6),
                          Text('Gửi đánh giá', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nút toggle form
              Row(
                children: [
                  const Expanded(
                    child: Text('Đánh giá giáo viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isShowingReviewForm = !_isShowingReviewForm),
                      icon: Icon(_isShowingReviewForm ? Icons.close : Icons.rate_review, size: 16),
                      label: Text(_isShowingReviewForm ? 'Đóng' : 'Viết đánh giá'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Tổng số đánh giá: ${profile.totalReviews}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),

              // Form đánh giá
              if (_isShowingReviewForm) ...[
                _buildReviewForm(),
                const SizedBox(height: 16),
              ],

              const Divider(height: 24),

              // Danh sách đánh giá
              const Text('Đánh giá từ học viên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Obx(() {
                if (vm.isLoadingReviews.value) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (vm.teacherReviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Chưa có đánh giá nào.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vm.teacherReviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, idx) {
                    final r = vm.teacherReviews[idx];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: (r['learnerAvatar'] != null && (r['learnerAvatar'] as String).isNotEmpty)
                              ? NetworkImage(r['learnerAvatar'])
                              : null,
                          child: (r['learnerAvatar'] == null || (r['learnerAvatar'] as String).isEmpty)
                              ? const Icon(Icons.person, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(r['learnerName'] ?? 'Ẩn danh', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  Text(r['createdAt'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < (r['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                    color: const Color(0xFFFFB800),
                                    size: 16,
                                  );
                                }),
                              ),
                              if ((r['comment'] ?? '').toString().trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text((r['comment'] ?? '').toString(), style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.4)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
