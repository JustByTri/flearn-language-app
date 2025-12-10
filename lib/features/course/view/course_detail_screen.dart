import 'package:flearn_app/features/course/view/payment_course_webview_screeb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:get/get.dart';
import '../../course_progress/viewmodel/course_progress_viewmodel.dart';
import '../model/course_detail.dart';
import '../viewmodel/course_viewmodel.dart';
import 'course_unit_screen.dart';
import 'package:flearn_app/features/teacher/view/teacher_profile_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final bool showTeacherProfile;
  const CourseDetailScreen({super.key, required this.courseId, this.showTeacherProfile = true});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseViewModel vm = Get.find<CourseViewModel>();
  String? _purchaseId;
  bool _isEnrolled = false;
  int _selectedTab = 0; // 0: Tổng quan, 1: Nội dung
  String? _enrollmentId;

  // NEW: state form đánh giá
  bool _forceShowReviewForm = false;
  bool _isShowingReviewForm = false;
  final TextEditingController _reviewController = TextEditingController();
  int _reviewRating = 0;

  @override
  void initState() {
    super.initState();
    // NEW: đọc flag để bật form review
    final args = Get.arguments;
    if (args is Map && args['showReviewForm'] == true) {
      _forceShowReviewForm = true; // chỉ ghi nhận flag, không auto mở form
    }
    if (vm.courseDetail.value == null || vm.courseDetail.value?.courseId != widget.courseId) {
      vm.fetchCourseDetail(widget.courseId);
    }
    vm.fetchCourseAccess(widget.courseId).then((_) {
      final access = vm.courseAccess.value;
      if (access != null && access.hasAccess) {
        setState(() {
          _isEnrolled = true;
          _enrollmentId = access.enrollmentId;
        });
      } else {
        setState(() {
          _isEnrolled = false;
          _forceShowReviewForm = false;   // NEW: prevent forcing when not enrolled
          _isShowingReviewForm = false;   // NEW: hide review form when not enrolled
        });
      }
    });

    // NEW: luôn fetch danh sách đánh giá khi vào màn
    vm.fetchCourseReviews(widget.courseId);
  }

  @override
  void dispose() {
    // NEW
    _reviewController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    if (price == 0) return 'Miễn phí';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫';
  }

  Future<void> _handleEnrollNow(BuildContext context) async {
    final vm = Get.find<CourseViewModel>();
    final courseProgressVM = Get.find<CourseProgressViewModel>();
    final course = vm.courseDetail.value!;

    if (course.price == 0) {
      // Luồng miễn phí: Gọi API enroll free trực tiếp
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      try {
        final enrollData = await vm.enrollFreeCourse(widget.courseId);
        if (Get.isDialogOpen ?? false) Get.back();
        if (enrollData != null) {
          setState(() {
            _isEnrolled = true;
            _enrollmentId = enrollData['enrollmentId'];
          });
          // Thêm: Refresh danh sách khóa học đang học
          await courseProgressVM.fetchMyCourses();
          await vm.fetchCourseAccess(widget.courseId);
          Get.snackbar('Thành công', 'Bạn đã đăng ký khóa học miễn phí thành công!', backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          Get.snackbar('Lỗi', 'Không thể đăng ký khóa học miễn phí. Vui lòng thử lại.');
        }
      } catch (e, st) {
        if (Get.isDialogOpen ?? false) Get.back();
        debugPrint('[Enroll Free] Exception: $e\n$st');
        Get.snackbar('Lỗi', 'Đã xảy ra lỗi: $e');
      }
    } else {
      // Luồng trả phí: Giữ logic cũ
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      try {
        if (_purchaseId == null) {
          final data = await vm.createPurchase(courseId: widget.courseId);
          if (data == null || data['purchaseId'] == null) {
            if (Get.isDialogOpen ?? false) Get.back();
            Get.snackbar('Lỗi', 'Không thể tạo đơn mua khóa học. Vui lòng thử lại.');
            return;
          }
          _purchaseId = data['purchaseId'].toString();
        }
        final paymentData = await vm.payPurchase(_purchaseId!);
        if (Get.isDialogOpen ?? false) Get.back();
        if (paymentData == null || paymentData['paymentUrl'] == null) {
          Get.snackbar('Lỗi', 'Không thể tạo thanh toán. Vui lòng thử lại.');
          return;
        }
        final paymentUrl = paymentData['paymentUrl'].toString();
        final transactionReference = paymentData['transactionReference']?.toString() ?? '';
        final paid = await Get.to<bool>(() => PaymentCourseWebViewScreen(
          paymentUrl: paymentUrl,
          purchaseId: _purchaseId!,
          transactionReference: transactionReference,
          amount: course.discountPrice ?? course.price,
        ));
        if (paid == true) {
          final enrollData = await vm.enrollCourse(widget.courseId);
          print('enrollData: $enrollData');
          final enrolled = enrollData != null;
          setState(() {
            _isEnrolled = enrolled;
            _enrollmentId = enrollData?['enrollmentId'];
          });
          if (enrolled) {
            print('enrolled: $enrolled' );
            // Thêm: Refresh danh sách khóa học đang học
            await courseProgressVM.fetchMyCourses();
            await vm.fetchCourseAccess(widget.courseId);
            Get.snackbar('Thành công', 'Bạn đã đăng ký khóa học thành công!', backgroundColor: Colors.green, colorText: Colors.white);
          } else {
            Get.snackbar('Lỗi', 'Thanh toán thành công nhưng ghi nhận enrollment thất bại!', backgroundColor: Colors.orange, colorText: Colors.white);
          }
        } else if (paid == false) {
          Get.snackbar('Đã hủy', 'Bạn đã hủy hoặc thất bại khi thanh toán.', backgroundColor: Colors.orange, colorText: Colors.white);
        }
      } catch (e, st) {
        if (Get.isDialogOpen ?? false) Get.back();
        debugPrint('[Enroll Paid] Exception: $e\n$st');
        Get.snackbar('Lỗi', 'Đã xảy ra lỗi: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Obx(() {
          if (vm.isLoadingDetail.value || vm.courseDetail.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final course = vm.courseDetail.value!;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.black),
                                onPressed: () {
                                  if (widget.showTeacherProfile == false) {
                                    // Quay lại đúng TeacherProfileScreen, không quay lại detail cũ
                                    Get.until((route) => route.settings.name == '/teacherProfile');
                                  } else {
                                    Get.back();
                                  }
                                },
                              ),
                              const Text(
                                'Chi tiết khóa học',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                      ),
                    ),


                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            course.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, size: 80, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level Badge & Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Trình độ: ${course.program?.level?.name ?? 'Sơ cấp'}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            course.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFFFB800), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                course.averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildInfoChip(Icons.people_outline, '${course.learnerCount}+ Đã đăng ký'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Info Row
                          Row(
                            children: [
                              _buildInfoItem(Icons.access_time, '${course.durationDays} ngày'),
                              const SizedBox(width: 20),
                              _buildInfoItem(Icons.play_circle_outline, '${course.numLessons} bài học'),
                              const SizedBox(width: 20),
                              _buildInfoItem(Icons.assignment_outlined, 'Bài tập'),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Tabs
                    _buildTabs(),

                    const Divider(height: 1),

                    // Tab Content - Hiển thị theo tab được chọn
                    if (_selectedTab == 0) ...[
                      // Tab Tổng quan
                      // Course Description
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mô tả khóa học',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              course.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Đọc thêm',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Topics Section
                      if (course.topics != null && course.topics!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chủ đề',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: course.topics!.map((topic) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primary.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      topic.topicName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                      // Learning Outcomes Section
                      if (course.learningOutcome != null && course.learningOutcome!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kết quả học tập',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              Builder(
                                builder: (context) {
                                  final outcomes = course.learningOutcome is List
                                      ? course.learningOutcome as List
                                      : [course.learningOutcome];

                                  return Column(
                                    children: outcomes.map((outcome) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 14,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                outcome.toString(),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                      // Teacher Profile
                      if (course.teacher != null && widget.showTeacherProfile)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Giáo viên',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () {
                                  // Kiểm tra nếu TeacherProfileScreen đã có trong stack thì pop về, nếu chưa thì push mới
                                  bool found = false;
                                  Get.until((route) {
                                    if (route.settings.name == '/teacherProfile') {
                                      found = true;
                                    }
                                    return true;
                                  });
                                  if (!found) {
                                    Get.to(() => TeacherProfileScreen(teacherId: course.teacher!.teacherId), routeName: '/teacherProfile');
                                  } else {
                                    Get.back();
                                  }
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: course.teacher!.avatar.isNotEmpty
                                          ? NetworkImage(course.teacher!.avatar)
                                          : null,
                                      child: course.teacher!.avatar.isEmpty
                                          ? const Icon(Icons.person, size: 30)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course.teacher!.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            course.teacher!.email,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      _buildReviewsSection(),
                      // if (_forceShowReviewForm && !_isShowingReviewForm)
                      //   Padding(
                      //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      //     child: SizedBox(
                      //       width: double.infinity,
                      //       child: ElevatedButton.icon(
                      //         onPressed: () => setState(() => _isShowingReviewForm = true),
                      //         icon: const Icon(Icons.rate_review),
                      //         label: const Text('Đánh giá khóa học này'),
                      //         style: ElevatedButton.styleFrom(
                      //           backgroundColor: AppColors.primary,
                      //           foregroundColor: Colors.white,
                      //           padding: const EdgeInsets.symmetric(vertical: 14),
                      //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      //           elevation: 2,
                      //         ),
                      //       ),
                      //     ),
                      //   ),

                      // // Form đánh giá chỉ hiện khi bấm nút
                      // if (_isShowingReviewForm)
                      //   Padding(
                      //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      //     child: _buildReviewForm(course.courseId),
                      //   ),
                    ] else if (_selectedTab == 1) ...[

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Builder(
                          builder: (context) {
                            final units = course.units;

                            if (units == null || units.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    'Chưa có nội dung',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nội dung khóa học (${units.length} chương)',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...units.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final unit = entry.value;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                                '${index + 1}',
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
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (unit.description.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    unit.description,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.play_lesson,
                                                      size: 16,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${unit.totalLessons} bài học',
                                                      style: TextStyle(
                                                        fontSize: 12,
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
                                }).toList(),
                              ],
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
      bottomNavigationBar: Obx(() {
        if (vm.courseDetail.value == null) return const SizedBox.shrink();
        final course = vm.courseDetail.value!;


        return _buildBottomBar(course);
      }),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: _buildTab('Tổng quan', _selectedTab == 0),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: _buildTab('Nội dung', _selectedTab == 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 40,
          height: isActive ? 3 : 0,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(CourseDetail course) {
    final access = vm.courseAccess.value;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (access == null || !access.hasAccess) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'Hoàn tiền trong 3 ngày',
                      style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chi phí',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        _formatPrice(course.discountPrice ?? course.price),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F1F1F), // giống UI mới
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isEnrolled
                          ? () {
                        Get.to(() => CourseUnitScreen(
                          courseId: course.courseId,
                          courseTitle: course.title,
                          enrollmentId: _enrollmentId, // NEW
                        ));
                      }
                          : () => _handleEnrollNow(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isEnrolled ? 'Bắt đầu học' : 'Đăng ký ngay',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Icon(_isEnrolled ? Icons.play_arrow : Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(() => CourseUnitScreen(
                      courseId: course.courseId,
                      courseTitle: course.title,
                      enrollmentId: _enrollmentId,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Bắt đầu học', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      const Icon(Icons.play_arrow, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    final isEnrolled = _isEnrolled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEnrolled) ...[
            Row(
              children: [
                const Expanded(
                  child: Text('Đánh giá khóa học', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() {
                      _isShowingReviewForm = !_isShowingReviewForm;
                      if (!_isShowingReviewForm) _reviewRating = 0;
                    }),
                    icon: Icon(_isShowingReviewForm ? Icons.close : Icons.rate_review, size: 16),
                    label: Text(_isShowingReviewForm ? 'Đóng' : 'Viết đánh giá'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isShowingReviewForm) ...[
              _buildReviewForm(vm.courseDetail.value!.courseId),
              const SizedBox(height: 16),
            ],
            const Divider(height: 24),
          ] else ...[
            const Text('Đánh giá từ học viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
          ],

          if (isEnrolled) const Text('Đánh giá từ học viên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (isEnrolled) const SizedBox(height: 8),

          Obx(() {
            if (vm.isLoadingReviews.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (vm.reviewsError.value != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Không tải được đánh giá: ${vm.reviewsError.value}',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              );
            }
            if (vm.courseReviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chưa có đánh giá nào.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.courseReviews.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final r = vm.courseReviews[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey.shade200, // dùng màu xám mặc định
                      backgroundImage: (r.learnerAvatar != null && r.learnerAvatar!.isNotEmpty)
                          ? NetworkImage(r.learnerAvatar!)
                          : null,
                      child: (r.learnerAvatar == null || r.learnerAvatar!.isEmpty)
                          ? const Icon(Icons.person, size: 18, color: Colors.grey)
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
                                child: Text(r.learnerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              Text(r.createdAt, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < r.rating ? Icons.star : Icons.star_border,
                                color: const Color(0xFFFFB800),
                                size: 16,
                              );
                            }),
                          ),
                          if (r.comment.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(r.comment, style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.4)),
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
  }

  Widget _buildReviewForm(String courseId) {
    final submitting = vm.isSubmittingReview.value;
    return Card(
      margin: const EdgeInsets.only(bottom: 0),
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
            const Text('Đánh giá của bạn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
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
                      color: filled ? Colors.amber : Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            const Text('Nhận xét của bạn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              enabled: !submitting,
              decoration: InputDecoration(
                hintText: 'Chia sẻ trải nghiệm của bạn về khóa học này...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
                  final res = await vm.submitCourseReview(
                    courseId: courseId,
                    rating: _reviewRating,
                    comment: comment.isEmpty ? ' ' : comment,
                  );

                  if (res != null) {
                    final status = res['status']?.toString().toLowerCase();
                    final code = res['code'] as int? ?? -1;
                    final duplicate = res['duplicate'] == true;
                    final msg = (res['message'] ?? '').toString();

                    if (status == 'success' && code >= 200 && code < 300) {
                      setState(() {
                        _forceShowReviewForm = false;
                        _isShowingReviewForm = false;
                        _reviewRating = 0;
                      });
                      _reviewController.clear();
                      vm.fetchCourseReviews(courseId);
                      Get.snackbar('Cảm ơn', 'Cảm ơn bạn đã đánh giá!');
                    } else if (duplicate || (code == 400 && msg.toLowerCase().contains('already reviewed'))) {
                      setState(() {
                        _forceShowReviewForm = false;
                        _isShowingReviewForm = false;
                      });
                      vm.fetchCourseReviews(courseId);
                      Get.snackbar('Thông báo', 'Bạn đã gửi đánh giá khóa học rồi');
                    } else if (code == 400 && msg.isNotEmpty) {
                      Get.snackbar('Bị từ chối', msg);
                    } else {
                      Get.snackbar('Lỗi', msg.isNotEmpty ? msg : 'Không gửi được đánh giá. Vui lòng thử lại.');
                    }
                  } else {
                    Get.snackbar('Lỗi', 'Không gửi được đánh giá. Vui lòng thử lại.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
}
