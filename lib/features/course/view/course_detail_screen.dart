import 'package:flearn_app/features/course/view/payment_course_webview_screeb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    super.initState();
    if (vm.courseDetail.value == null || vm.courseDetail.value?.courseId != widget.courseId) {
      vm.fetchCourseDetail(widget.courseId);
    }
    vm.fetchCourseAccess(widget.courseId).then((_) {
      final access = vm.courseAccess.value;
      if (access != null && access.hasAccess) {
        setState(() => _isEnrolled = true);
      } else {
        setState(() => _isEnrolled = false);
      }
    });
  }

  String _formatPrice(int price) {
    if (price == 0) return 'Miễn phí';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫';
  }

  Future<void> _handleEnrollNow(BuildContext context) async {
    final vm = Get.find<CourseViewModel>();
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
      final course = vm.courseDetail.value!;
      final paid = await Get.to<bool>(() => PaymentCourseWebViewScreen(
        paymentUrl: paymentUrl,
        purchaseId: _purchaseId!,
        transactionReference: transactionReference,
        amount: course.discountPrice ?? course.price,
      ));
      if (paid == true) {
        final enrollData = await vm.enrollCourse(widget.courseId); // nhận full data
        final enrolled = enrollData != null;
        setState(() {
          _isEnrolled = enrolled;
          _enrollmentId = enrollData?['enrollmentId'];
        });
        if (enrolled) {
          Get.snackbar('Thành công', 'Bạn đã đăng ký khóa học thành công!', backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          Get.snackbar('Lỗi', 'Thanh toán thành công nhưng ghi nhận enrollment thất bại!', backgroundColor: Colors.orange, colorText: Colors.white);
        }
      } else if (paid == false) {
        Get.snackbar('Đã hủy', 'Bạn đã hủy hoặc thất bại khi thanh toán.',
            backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e, st) {
      if (Get.isDialogOpen ?? false) Get.back();
      debugPrint('[Enroll] Exception: $e\n$st');
      Get.snackbar('Lỗi', 'Đã xảy ra lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
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
      bottomNavigationBar: Obx(() {
        if (vm.courseDetail.value == null) return const SizedBox.shrink();
        return _buildBottomBar(vm.courseDetail.value!);
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 0),
            child: _buildTab('Tổng quan', _selectedTab == 0),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 1),
            child: _buildTab('Nội dung', _selectedTab == 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        if (isActive)
          Container(
            width: 40,
            height: 3,
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
                        _formatPrice(course.discountPrice ?? course.price),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
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
              // Đã mua: chỉ hiện nút "Bắt đầu học", không hiện giá
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
}
