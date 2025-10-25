import 'package:flearn_app/features/auth/view/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/mainBottomNavbar.dart';
import '../../course/view/course_screen.dart';
import '../../auth/view/home_screen.dart';
import '../model/topic.dart';
import '../viewmodel/topic_viewmodel.dart';
import 'confirm_context_screen.dart';

class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final topicViewModel = Get.put(TopicViewModel(Get.find()));
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
    topicViewModel.fetchTopics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textLight),
            onPressed: () => navController.onDestinationSelected(0), // Quay về Home tab
          ),
          title: Text("Chủ đề", style: TextStyle(color: AppColors.textLight, fontSize: 20, fontWeight: FontWeight.w600)),
          elevation: 0,
          centerTitle: true,
        ),
        body: Obx(() {
          if (topicViewModel.isLoadingTopics.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final topics = topicViewModel.topics;

          if (topics.isEmpty) {
            return const Center(
              child: Text("Chưa có chủ đề nào", style: TextStyle(fontSize: 16)),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
              itemCount: topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final topic = topics[index];
                return _buildTopicRow(topic, index);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopicRow(TopicModel topic, int index) {

    final List<List<Color>> gradients = [
      [Colors.blue.shade200, Colors.blue.shade400],
      [Colors.green.shade200, Colors.green.shade400],
      [Colors.orange.shade200, Colors.orange.shade400],
      [Colors.purple.shade200, Colors.purple.shade400],
      [Colors.red.shade200, Colors.red.shade400],
    ];
    final gradient = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ConfirmContextScreen(topic: topic)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    topic.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}