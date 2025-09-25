import 'package:flutter/material.dart';

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
      progress: 0.7,
      completedTasks: 12,
      totalTasks: 15,
      color: const Color(0xFF4CAF50),
      description: "Cải thiện kỹ năng phát âm tiếng Anh",
      isFree: true,
    ),
    Lesson(
      title: "Japanese Basics",
      progress: 0.4,
      completedTasks: 8,
      totalTasks: 20,
      color: const Color(0xFFF44336),
      description: "Học phát âm và từ vựng tiếng Nhật cơ bản",
      isFree: false,
    ),
    Lesson(
      title: "Chinese Vocabulary",
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
    const fptOrange = Color(0xFFFF8300);
    const fptBlue = Color(0xFF0055A5);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(fptOrange),
              _buildContent(fptOrange, fptBlue),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(fptOrange),
    );
  }

  Widget _buildSliverAppBar(Color fptOrange) {
    return SliverAppBar(
      expandedHeight: 200,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildStreak(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Xin chào! 👋",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Sẵn sàng luyện tập hôm nay?",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: const Icon(Icons.person, color: Colors.white, size: 30),
        ),
      ],
    );
  }

  Widget _buildStreak() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            "Streak: 7 ngày",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color fptOrange, Color fptBlue) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActions(fptBlue),
            const SizedBox(height: 32),
            _buildLessonsSection("Bài học miễn phí", lessonsInProgress.where((lesson) => lesson.isFree).toList()),
            const SizedBox(height: 32),
            _buildLessonsSection("Bài học có phí", lessonsInProgress.where((lesson) => !lesson.isFree).toList()),
            const SizedBox(height: 32),
            _buildTodaysGoal(fptOrange, fptBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(Color fptBlue) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.mic,
            title: "Luyện phát âm",
            subtitle: "15 phút",
            color: fptBlue,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.headphones,
            title: "Nghe nói",
            subtitle: "10 phút",
            color: const Color(0xFF9C27B0),
            onTap: () {},
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
        padding: const EdgeInsets.all(20),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsSection(String title, List<Lesson> lessons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ...lessons.asMap().entries.map((entry) {
          int index = entry.key;
          Lesson lesson = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index == lessons.length - 1 ? 0 : 16),
            child: _buildLessonCard(lesson),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: lesson.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Icon(Icons.book, color: lesson.color, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.task, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          "${lesson.completedTasks}/${lesson.totalTasks} nhiệm vụ",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: lesson.color,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  lesson.isFree ? "Học miễn phí" : "Học ngay",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "${(lesson.progress * 100).toInt()}%",
                    style: TextStyle(
                      color: lesson.color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: lesson.progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(lesson.color),
                minHeight: 6,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysGoal(Color fptOrange, Color fptBlue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [fptBlue.withOpacity(0.1), fptOrange.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fptOrange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, size: 48, color: fptOrange),
          const SizedBox(height: 12),
          Text(
            "Mục tiêu hôm nay",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hoàn thành 2/3 bài học",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.67,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(fptOrange),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bài học"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Luyện tập"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Hồ sơ"),
        ],
      ),
    );
  }
}

class Lesson {
  final String title;
  final double progress;
  final int completedTasks;
  final int totalTasks;
  final Color color;
  final String description;
  final bool isFree;

  Lesson({
    required this.title,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.color,
    required this.description,
    required this.isFree,
  });
}