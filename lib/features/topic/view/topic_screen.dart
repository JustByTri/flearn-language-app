import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:get/get.dart';

import '../model/topic.dart';
import '../viewmodel/topic_viewmodel.dart';
import 'confirm_context_screen.dart';

class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final topicViewModel = Get.put(TopicViewModel(Get.find()));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      topicViewModel.fetchTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // A very light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Chủ đề Roleplay",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Obx(() {
        if (topicViewModel.isLoadingTopics.value) {
          return const Center(child: CupertinoActivityIndicator(radius: 15));
        }

        if (topicViewModel.topics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.bubble_left_bubble_right, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  "Chưa có chủ đề nào",
                  style: TextStyle(fontSize: 17, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final topics = topicViewModel.topics;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            return _buildTopicCard(topic, index);
          },
        );
      }),
    );
  }

  Widget _buildTopicCard(TopicModel topic, int index) {
    final List<List<Color>> gradients = [
      [const Color(0xFF6DD5FA), const Color(0xFF2980B9)],
      [const Color(0xFFC5E1A5), const Color(0xFF7CB342)],
      [const Color(0xFFFFD54F), const Color(0xFFFFA000)],
      [const Color(0xFFCE93D8), const Color(0xFF8E24AA)],
      [const Color(0xFFEF9A9A), const Color(0xFFD32F2F)],
      [const Color(0xFF81D4FA), const Color(0xFF0277BD)],
    ];
    final gradient = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ConfirmContextScreen(topic: topic),
          transition: Transition.cupertino,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[1].withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,1))]
              ),
            ),
            const SizedBox(height: 8),
            Text(
              topic.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Luyện tập ngay",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.arrow_right,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
