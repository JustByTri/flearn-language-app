import 'package:flearn_app/core/constants/colors.dart';
import 'package:flearn_app/features/auth/view/speaking_screen.dart';
import 'package:flearn_app/features/topic/view/topic_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../../../shared/widgets/mainBottomNavbar.dart';
import 'profile_screen.dart';
import '../../course/view/course_screen.dart';
import '../../survey/view/survey_screen.dart';
import '../../../shared/widgets/app_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final lessonsInProgress = [
    Lesson(
      title: "English Pronunciation",
      topic: "Pronunciation",
      progress: 0.7,
      completedTasks: 12,
      totalTasks: 15,
      color: AppColors.success,
      description: "Cải thiện kỹ năng phát âm tiếng Anh",
      isFree: true,
    ),
    Lesson(
      title: "Japanese Basics",
      topic: "Vocabulary",
      progress: 0.4,
      completedTasks: 8,
      totalTasks: 20,
      color: AppColors.error,
      description: "Học phát âm và từ vựng tiếng Nhật cơ bản",
      isFree: false,
    ),
    Lesson(
      title: "Chinese Vocabulary",
      topic: "Vocabulary",
      progress: 0.2,
      completedTasks: 3,
      totalTasks: 10,
      color: AppColors.info,
      description: "Mở rộng vốn từ vựng tiếng Trung",
      isFree: true,
    ),
  ];

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
            if (GetStorage().read('surveyCompleted') != true) _buildSurveyBanner(),
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
            _buildLessonsSection("Bài học miễn phí", lessonsInProgress.where((lesson) => lesson.isFree).toList()),
            const SizedBox(height: 24),
            _buildLessonsSection("Bài học có phí", lessonsInProgress.where((lesson) => !lesson.isFree).toList()),
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
            title: "Luyện phát âm",
            subtitle: "15 phút",
            color: AppColors.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeakingPracticeScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.headphones,
            title: "Nghe nói",
            subtitle: "10 phút",
            color: AppColors.accent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseScreen())),
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

  Widget _buildLessonsSection(String title, List<Lesson> lessons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...lessons.map((lesson) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildLessonCard(lesson),
        )),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mở khóa học: ${lesson.title}"))),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: lesson.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.book, color: lesson.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lesson.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1),
                          const SizedBox(height: 4),
                          Text(lesson.description, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.task, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text("${lesson.completedTasks}/${lesson.totalTasks} nhiệm vụ", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: lesson.color, borderRadius: BorderRadius.circular(12)),
                      child: Text(lesson.isFree ? "Miễn phí" : "Học ngay", style: TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tiến độ", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text("${(lesson.progress * 100).toInt()}%", style: TextStyle(color: lesson.color, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: lesson.progress,
                      backgroundColor: AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(lesson.color),
                      minHeight: 6,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(child: Text("Vui lòng hoàn thành khảo sát để có trải nghiệm tốt hơn!")),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SurveyScreen())),
              child: Text("Hoàn thành ngay", style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

class Lesson {
  final String title;
  final String topic;
  final double progress;
  final int completedTasks;
  final int totalTasks;
  final Color color;
  final String description;
  final bool isFree;

  Lesson({
    required this.title,
    required this.topic,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.color,
    required this.description,
    required this.isFree,
  });
}