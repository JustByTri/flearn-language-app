import 'package:flutter/material.dart';

class CourseScreen extends StatefulWidget {
  final String? topic; // Optional filter by topic
  const CourseScreen({super.key, this.topic});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Lesson> lessons = [
    Lesson(
      title: "English Pronunciation",
      topic: "Pronunciation",
      progress: 0.7,
      completedTasks: 12,
      totalTasks: 15,
      color: const Color(0xFF4CAF50),
      description: "Cải thiện kỹ năng phát âm tiếng Anh với các bài tập thực hành",
      isFree: true,
    ),
    Lesson(
      title: "Japanese Pronunciation",
      topic: "Pronunciation",
      progress: 0.3,
      completedTasks: 5,
      totalTasks: 20,
      color: const Color(0xFF4CAF50),
      description: "Học cách phát âm chuẩn tiếng Nhật",
      isFree: false,
    ),
    Lesson(
      title: "English Vocabulary",
      topic: "Vocabulary",
      progress: 0.5,
      completedTasks: 10,
      totalTasks: 20,
      color: const Color(0xFFF44336),
      description: "Mở rộng vốn từ vựng tiếng Anh hàng ngày",
      isFree: true,
    ),
    Lesson(
      title: "Chinese Vocabulary",
      topic: "Vocabulary",
      progress: 0.2,
      completedTasks: 3,
      totalTasks: 10,
      color: const Color(0xFFF44336),
      description: "Học từ vựng tiếng Trung cơ bản",
      isFree: true,
    ),
    Lesson(
      title: "English Grammar",
      topic: "Grammar",
      progress: 0.6,
      completedTasks: 8,
      totalTasks: 12,
      color: const Color(0xFF2196F3),
      description: "Nắm vững ngữ pháp tiếng Anh cơ bản",
      isFree: false,
    ),
    Lesson(
      title: "Japanese Grammar",
      topic: "Grammar",
      progress: 0.4,
      completedTasks: 6,
      totalTasks: 15,
      color: const Color(0xFF2196F3),
      description: "Học cấu trúc ngữ pháp tiếng Nhật",
      isFree: false,
    ),
    Lesson(
      title: "English Listening",
      topic: "Listening",
      progress: 0.8,
      completedTasks: 16,
      totalTasks: 20,
      color: const Color(0xFFFF9800),
      description: "Luyện nghe tiếng Anh qua hội thoại thực tế",
      isFree: true,
    ),
    Lesson(
      title: "Spanish Listening",
      topic: "Listening",
      progress: 0.1,
      completedTasks: 2,
      totalTasks: 15,
      color: const Color(0xFFFF9800),
      description: "Cải thiện kỹ năng nghe tiếng Tây Ban Nha",
      isFree: false,
    ),
    Lesson(
      title: "English Speaking",
      topic: "Speaking",
      progress: 0.5,
      completedTasks: 7,
      totalTasks: 14,
      color: const Color(0xFF9C27B0),
      description: "Luyện kỹ năng nói tiếng Anh tự tin",
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

    // Filter lessons by topic if provided
    final filteredLessons = widget.topic != null
        ? lessons.where((lesson) => lesson.topic == widget.topic).toList()
        : lessons;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF8300),
          title: Text(
            widget.topic != null ? "Khóa học ${widget.topic}" : "Tất cả khóa học",
            style: TextStyle(color: Colors.white, fontSize: 20 * fontScale),
          ),
          elevation: 0,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.topic != null ? "Khóa học trong ${widget.topic}" : "Tất cả khóa học",
                          style: TextStyle(
                            fontSize: 22 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: padding),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredLessons.length,
                            itemBuilder: (context, index) {
                              final lesson = filteredLessons[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: index == filteredLessons.length - 1 ? 0 : padding),
                                child: _buildLessonCard(lesson, size, fontScale),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson, Size size, double fontScale) {
    return GestureDetector(
      onTap: () {
        // Placeholder: Navigate to CourseDetailScreen
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