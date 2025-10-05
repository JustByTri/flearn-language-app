import 'package:flearn_app/features/auth/view/profile_screen.dart';
import 'package:flearn_app/features/topic/view/topic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/mainBottomNavbar.dart';
import '../../auth/view/home_screen.dart';
import '../model/course.dart';
import '../viewmodel/course_viewmodel.dart';


class CourseScreen extends StatefulWidget {
  final String? topic;
  const CourseScreen({super.key, this.topic});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late final CourseViewModel courseViewModel;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    courseViewModel = Get.put(CourseViewModel(Get.find()));
    courseViewModel.fetchCourses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textLight),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
          ),
          title: Text("Khóa học", style: TextStyle(color: AppColors.textLight, fontSize: 20)),
          elevation: 0,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                if (courseViewModel.isLoadingCourse.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final courses = courseViewModel.courses;
                if (courses.isEmpty) {
                  return const Center(child: Text('Không có khóa học nào'));
                }
                return ListView.separated(
                  itemCount: courses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return _buildCourseCard(course);
                  },
                );
              }),
            ),
          ),
        ),
        bottomNavigationBar: MainBottomNavBar(
          currentIndex: 2,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                break;
              case 1:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TopicScreen()));
                break;
              case 2:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CourseScreen()));
                break;
              case 3:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mở khóa học: ${course.title}")),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            course.imageUrl.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(course.imageUrl, width: 48, height: 48, fit: BoxFit.cover),
            )
                : Icon(Icons.book, color: AppColors.primary, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(course.description, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text('Giá: ${course.price}đ, Giảm còn: ${course.discountPrice}đ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('Giáo viên: ${course.teacherName}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('Ngôn ngữ: ${course.language}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('Trình độ: ${course.courseLevel}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('Kỹ năng: ${course.courseSkill}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: course.courseType == "Free" ? AppColors.success : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                course.courseType == "Free" ? "Miễn phí" : "Trả phí",
                style: TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}