import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'profile_screen.dart';
import 'topic_screen.dart';
import 'course_screen.dart';
import 'survey_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;



  final List<Lesson> lessonsInProgress = [
    Lesson(
      title: "English Pronunciation",
      topic: "Pronunciation",
      progress: 0.7,
      completedTasks: 12,
      totalTasks: 15,
      color: const Color(0xFF4CAF50),
      description: "Cải thiện kỹ năng phát âm tiếng Anh",
      isFree: true,
    ),
    Lesson(
      title: "Japanese Basics",
      topic: "Vocabulary",
      progress: 0.4,
      completedTasks: 8,
      totalTasks: 20,
      color: const Color(0xFFF44336),
      description: "Học phát âm và từ vựng tiếng Nhật cơ bản",
      isFree: false,
    ),
    Lesson(
      title: "Chinese Vocabulary",
      topic: "Vocabulary",
      progress: 0.2,
      completedTasks: 3,
      totalTasks: 10,
      color: const Color(0xFF2196F3),
      description: "Mở rộng vốn từ vựng tiếng Trung",
      isFree: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
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
    final size = MediaQuery.of(context).size;
    final isTabletOrLarger = size.width >= 600;
    final fontScale = isTabletOrLarger ? 1.2 : 1.0;
    final padding = size.width * 0.05;
    const fptOrange = Color(0xFFFF8300);
    const fptBlue = Color(0xFF0055A5);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(fptOrange, size, fontScale),
            _buildContent(fptOrange, fptBlue, size, fontScale, padding),
            if (GetStorage().read('surveyCompleted') != true)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text("Vui lòng hoàn thành khảo sát để có trải nghiệm tốt hơn!"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SurveyScreen())),
                        child: const Text("Hoàn thành ngay"),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(fptOrange),
      ),
    );
  }

  Widget _buildSliverAppBar(Color fptOrange, Size size, double fontScale) {
    return SliverAppBar(
      expandedHeight: size.height * 0.25,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [fptOrange, fptOrange.withOpacity(0.7)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(size.width * 0.025),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(size, fontScale),
                  SizedBox(height: size.width * 0.025),
                  _buildStreak(fontScale),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Size size, double fontScale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Xin chào! 👋",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24 * fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Sẵn sàng luyện tập hôm nay?",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16 * fontScale,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: 16 * fontScale),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: CircleAvatar(
            radius: size.width * 0.05,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(Icons.person, color: Colors.white, size: size.width * 0.06),
          ),
        ),
      ],
    );
  }

  Widget _buildStreak(double fontScale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * fontScale, vertical: 8 * fontScale),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: Colors.white, size: 20 * fontScale),
          SizedBox(width: 8 * fontScale),
          Text(
            "Streak: 7 ngày",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14 * fontScale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color fptOrange, Color fptBlue, Size size, double fontScale, double padding) {
    return SliverToBoxAdapter(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActions(fptBlue, size, fontScale, padding),
              SizedBox(height: padding * 1.6),
              _buildLessonsSection("Bài học miễn phí", lessonsInProgress.where((lesson) => lesson.isFree).toList(), size, fontScale, padding),
              SizedBox(height: padding * 1.6),
              _buildLessonsSection("Bài học có phí", lessonsInProgress.where((lesson) => !lesson.isFree).toList(), size, fontScale, padding),
              SizedBox(height: padding * 1.6),
              _buildTodaysGoal(fptOrange, fptBlue, size, fontScale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(Color fptBlue, Size size, double fontScale, double padding) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.mic,
            title: "Luyện phát âm",
            subtitle: "15 phút",
            color: fptBlue,
            size: size,
            fontScale: fontScale,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CourseScreen(topic: "Pronunciation")),
              );
            },
          ),
        ),
        SizedBox(width: padding * 0.6),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.headphones,
            title: "Nghe nói",
            subtitle: "10 phút",
            color: const Color(0xFF9C27B0),
            size: size,
            fontScale: fontScale,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CourseScreen()),
              );
            },
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
    required Size size,
    required double fontScale,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size.width * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(size.width * 0.03),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: size.width * 0.06),
            ),
            SizedBox(height: size.width * 0.03),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14 * fontScale,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: size.width * 0.01),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12 * fontScale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsSection(String title, List<Lesson> lessons, Size size, double fontScale, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22 * fontScale,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: padding),
        ...lessons.asMap().entries.map((entry) {
          int index = entry.key;
          Lesson lesson = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index == lessons.length - 1 ? 0 : padding),
            child: _buildLessonCard(lesson, size, fontScale),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson, Size size, double fontScale) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mở khóa học: ${lesson.title}")),
        );
      },
      child: Container(
        padding: EdgeInsets.all(size.width * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: size.width * 0.15,
                  height: size.width * 0.15,
                  decoration: BoxDecoration(
                    color: lesson.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(size.width * 0.075),
                  ),
                  child: Center(
                    child: Icon(Icons.book, color: lesson.color, size: size.width * 0.07),
                  ),
                ),
                SizedBox(width: size.width * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 18 * fontScale,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4 * fontScale),
                      Text(
                        lesson.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14 * fontScale,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8 * fontScale),
                      Row(
                        children: [
                          Icon(Icons.task, size: 16 * fontScale, color: Colors.grey[500]),
                          SizedBox(width: 4 * fontScale),
                          Expanded(
                            child: Text(
                              "${lesson.completedTasks}/${lesson.totalTasks} nhiệm vụ",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12 * fontScale,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.03, vertical: 6 * fontScale),
                  decoration: BoxDecoration(
                    color: lesson.color,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    lesson.isFree ? "Miễn phí" : "Học ngay",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12 * fontScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.width * 0.04),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tiến độ",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14 * fontScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${(lesson.progress * 100).toInt()}%",
                      style: TextStyle(
                        color: lesson.color,
                        fontSize: 14 * fontScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8 * fontScale),
                LinearProgressIndicator(
                  value: lesson.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(lesson.color),
                  minHeight: 6 * fontScale,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysGoal(Color fptOrange, Color fptBlue, Size size, double fontScale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [fptBlue.withOpacity(0.1), fptOrange.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fptOrange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, size: 48 * fontScale, color: fptOrange),
          SizedBox(height: 12 * fontScale),
          Text(
            "Mục tiêu hôm nay",
            style: TextStyle(
              fontSize: 18 * fontScale,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8 * fontScale),
          Text(
            "Hoàn thành 2/3 bài học",
            style: TextStyle(
              fontSize: 14 * fontScale,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16 * fontScale),
          LinearProgressIndicator(
            value: 0.67,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(fptOrange),
            minHeight: 6 * fontScale,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(Color fptOrange) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: fptOrange,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
            // Stay on HomeScreen
              break;
            case 1:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TopicScreen()));
              break;
            case 2:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CourseScreen()));
              break;
            case 3:
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Chủ đề"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Khóa học"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Hồ sơ"),
        ],
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