import 'package:flearn_app/core/constants/colors.dart';
import 'package:flearn_app/features/topic/view/topic_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../shared/widgets/mainBottomNavbar.dart';
import '../../course/viewmodel/course_viewmodel.dart';
import '../../schedule/view/schedule_screen.dart';
import '../../survey/model/assessment_result.dart';
import '../../survey/view/assessment_result_screen.dart';
import 'profile_screen.dart';
import '../../course/view/course_screen.dart';
import '../../survey/view/survey_screen.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../course/model/course.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  CourseViewModel? courseViewModel;


  final List<TeacherSchedule> teacherSchedules = [

    TeacherSchedule(
      teacherId: "t1",
      teacherName: "John Smith",
      teacherAvatar: "",
      language: "English",
      date: "2025-10-22",
      time: "19:00",
      duration: 60,
      price: 150000,
      maxStudents: 10,
      currentStudents: 7,
      description: "Conversation practice session",
    ),
    TeacherSchedule(
      teacherId: "t2",
      teacherName: "Yamada Sensei",
      teacherAvatar: "",
      language: "Japanese",
      date: "2025-10-23",
      time: "20:00",
      duration: 45,
      price: 200000,
      maxStudents: 8,
      currentStudents: 5,
      description: "Grammar and pronunciation",
    ),
  ];

  int unreadNotifications = 3;

  @override
  void initState() {
    super.initState();
    _initializeCourseViewModel();

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

    _loadData();
  }

  void _initializeCourseViewModel() {
    try {
      courseViewModel = Get.find<CourseViewModel>();
    } catch (e) {
      print('CourseViewModel không tìm thấy, tạo mới: $e');
      try {
        courseViewModel = Get.put(CourseViewModel(Get.find()));
      } catch (e2) {
        print('Lỗi khởi tạo CourseViewModel: $e2');
        courseViewModel = null;
      }
    }
  }

  Future<void> _loadData() async {
    if (courseViewModel != null) {
      try {
        await courseViewModel!.fetchCourses();
      } catch (e) {
        print('Lỗi tải courses: $e');
      }
    }
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
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            _buildContent(),
            _buildSurveyBanner()
          ],
        ),
        bottomNavigationBar: MainBottomNavBar(
          currentIndex: 0,
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

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Xin chào! 👋", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                        Text("Sẵn sàng luyện tập hôm nay?", style: TextStyle(fontSize: 16, color: AppColors.textLight.withOpacity(0.9))),
                      ],
                    ),
                    Row(
                      children: [
                        // Bell notification icon
                        Stack(
                          children: [
                            IconButton(
                              icon: Icon(Icons.notifications, color: AppColors.textLight, size: 28),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()));
                              },
                            ),
                            if (unreadNotifications > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '$unreadNotifications',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.textLight.withOpacity(0.2),
                            child: Icon(Icons.person, color: AppColors.textLight, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, color: AppColors.textLight, size: 18),
                      const SizedBox(width: 6),
                      Text("Streak: 7 ngày", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActions(),
            const SizedBox(height: 24),
            courseViewModel != null
                ? Obx(() {
              if (courseViewModel!.isLoadingCourse.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final courses = courseViewModel!.courses;
              if (courses.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.school, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "Chưa có khóa học nào",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Vui lòng quay lại sau",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final freeCourses = courses.where((c) => c.courseType == "Free").toList();
              final paidCourses = courses.where((c) => c.courseType != "Free").toList();

              return Column(
                children: [
                  if (freeCourses.isNotEmpty) ...[
                    _buildCoursesSection("📚 Khóa học miễn phí", freeCourses),
                    const SizedBox(height: 24),
                  ],
                  if (paidCourses.isNotEmpty) ...[
                    _buildCoursesSection("💎 Khóa học có phí", paidCourses),
                    const SizedBox(height: 24),
                  ],
                ],
              );
            })
                : Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "Không thể tải danh sách khóa học",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Vui lòng kiểm tra kết nối mạng",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _initializeCourseViewModel();
                      _loadData();
                    },
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            ),
            _buildTeacherScheduleSection(),
            const SizedBox(height: 24),
            _buildTodaysGoal(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.mic,
            title: "Luyện với ai",
            subtitle: "15 phút",
            color: AppColors.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopicScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.schedule,
            title: "Lịch học",
            subtitle: "Xem tất cả",
            color: AppColors.accent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherScheduleListScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 2),
            Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesSection(String title, List<Course> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseScreen()));
              },
              child: Text("Xem tất cả", style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index == courses.length - 1 ? 0 : 12),
                child: _buildCourseCard(courses[index]),
              );
            },
          ),
        ),
      ],
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
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: course.courseType == "Free" ? Colors.green : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    course.courseType == "Free" ? "MIỄN PHÍ" : "${course.price ~/ 1000}K VNĐ",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Text("4.5", style: TextStyle(fontSize: 12)), // Cố định rating vì model chưa có
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(course.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1),
            const SizedBox(height: 4),
            Text(course.description, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(course.teacherName, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.quiz, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text("${course.numLessons} bài", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("👨‍🏫 Lịch dạy học", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherScheduleListScreen()));
              },
              child: Text("Xem tất cả", style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: teacherSchedules.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index == teacherSchedules.length - 1 ? 0 : 12),
                child: _buildTeacherScheduleCard(teacherSchedules[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherScheduleCard(TeacherSchedule schedule) {
    final isAlmostFull = schedule.currentStudents >= schedule.maxStudents * 0.8;

    return GestureDetector(
      onTap: () {

        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => TeacherDetailScreen(schedule: schedule),
        // ));
      },
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isAlmostFull ? Border.all(color: Colors.orange, width: 2) : null,
          boxShadow: [BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(schedule.teacherName[0], style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(schedule.teacherName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                      Text(schedule.language, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text("${schedule.date} ${schedule.time}", style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text("${schedule.currentStudents}/${schedule.maxStudents}", style: TextStyle(fontSize: 12)),
                if (isAlmostFull) ...[
                  const SizedBox(width: 8),
                  Text("Sắp đầy!", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${schedule.price ~/ 1000}K VNĐ", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("Đặt lịch", style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysGoal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.1), AppColors.accent.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, size: 40, color: AppColors.primary),
          const SizedBox(height: 8),
          Text("Mục tiêu hôm nay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text("Hoàn thành 2/3 bài học", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.67,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyBanner() {
    final box = GetStorage();
    final surveyStatus = box.read('surveyStatus');
    final hasDoneSurvey = surveyStatus != null && surveyStatus['assessmentRequired'] == false;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasDoneSurvey ? AppColors.info.withOpacity(0.15) : AppColors.warning.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(hasDoneSurvey ? Icons.emoji_events : Icons.warning, color: hasDoneSurvey ? AppColors.info : AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasDoneSurvey
                    ? "Bạn đã hoàn thành khảo sát. Xem lại kết quả đánh giá của bạn!"
                    : "Vui lòng hoàn thành khảo sát để có trải nghiệm tốt hơn!",
              ),
            ),
            TextButton(
              onPressed: () async {
                if (hasDoneSurvey) {
                  final result = box.read('assessmentResult');
                  if (result != null) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AssessmentResultScreen(result: AssessmentResult.fromJson(result)),
                    ));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Không tìm thấy kết quả đánh giá!")),
                    );
                  }
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SurveyScreen()));
                }
              },
              child: Text(
                hasDoneSurvey ? "Xem lại đánh giá" : "Hoàn thành ngay",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherSchedule {
  final String teacherId;
  final String teacherName;
  final String teacherAvatar;
  final String language;
  final String date;
  final String time;
  final int duration;
  final int price;
  final int maxStudents;
  final int currentStudents;
  final String description;

  TeacherSchedule({
    required this.teacherId,
    required this.teacherName,
    required this.teacherAvatar,
    required this.language,
    required this.date,
    required this.time,
    required this.duration,
    required this.price,
    required this.maxStudents,
    required this.currentStudents,
    required this.description,
  });
}

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo"),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text("Danh sách thông báo sẽ được triển khai sau"),
      ),
    );
  }
}
