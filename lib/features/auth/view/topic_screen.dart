import 'package:flutter/material.dart';

import 'course_screen.dart';

class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Topic> topics = [
    Topic(
      title: "Pronunciation",
      description: "Improve your speaking clarity and accent",
      icon: Icons.mic,
      color: const Color(0xFF4CAF50),
    ),
    Topic(
      title: "Vocabulary",
      description: "Expand your word knowledge for daily use",
      icon: Icons.book,
      color: const Color(0xFFF44336),
    ),
    Topic(
      title: "Grammar",
      description: "Master sentence structure and rules",
      icon: Icons.edit,
      color: const Color(0xFF2196F3),
    ),
    Topic(
      title: "Listening",
      description: "Enhance your listening comprehension",
      icon: Icons.headphones,
      color: const Color(0xFFFF9800),
    ),
    Topic(
      title: "Speaking",
      description: "Practice conversational skills",
      icon: Icons.record_voice_over,
      color: const Color(0xFF9C27B0),
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF8300),
          title: Text(
            "Chủ đề",
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
                    child: ListView.builder(
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: index == topics.length - 1 ? 0 : padding),
                          child: _buildTopicCard(topic, size, fontScale),
                        );
                      },
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

  Widget _buildTopicCard(Topic topic, Size size, double fontScale) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseScreen(topic: topic.title),
          ),
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
        child: Row(
          children: [
            Container(
              width: size.width * 0.15,
              height: size.width * 0.15,
              decoration: BoxDecoration(
                color: topic.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(size.width * 0.075),
              ),
              child: Icon(topic.icon, color: topic.color, size: size.width * 0.07),
            ),
            SizedBox(width: size.width * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: TextStyle(
                      fontSize: 18 * fontScale,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * fontScale),
                  Text(
                    topic.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14 * fontScale,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Topic {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  Topic({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}