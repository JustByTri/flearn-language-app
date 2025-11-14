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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tổng số đánh giá: ${profile.totalReviews}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('(Chi tiết đánh giá chưa khả dụng ở thời điểm hiện tại)'),
        ],
      ),
    );
  }
}
