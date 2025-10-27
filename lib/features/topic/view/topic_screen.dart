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

        title: const Text(
          "Chủ đề Roleplay",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: topicViewModel.fetchTopics,
        child: Obx(() {
          if (topicViewModel.isLoadingTopics.value &&
              topicViewModel.topics.isEmpty) {
            return const Center(child: CupertinoActivityIndicator(radius: 15));
          }

          if (topicViewModel.topics.isEmpty) {
            return Center(
              child: ListView(
                // Use ListView to make the empty message scrollable and work with RefreshIndicator
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Icon(CupertinoIcons.bubble_left_bubble_right,
                      size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    "Chưa có chủ đề nào",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final topics = topicViewModel.topics;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return _buildTopicCard(topic, index);
            },
          );
        }),
      ),
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
        padding: const EdgeInsets.all(16),
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
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1))
                      ]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  topic.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.3,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  CupertinoIcons.arrow_right_circle_fill,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
