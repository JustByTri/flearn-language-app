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

class _TopicScreenState extends State<TopicScreen> with WidgetsBindingObserver {
  final topicViewModel = Get.put(TopicViewModel(Get.find()));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      topicViewModel.fetchTopics();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Gọi lại API để cập nhật số lượt luyện tập
      final topicViewModel = Get.find<TopicViewModel>();
      topicViewModel.fetchConversationUsage();
    }
  }

  // Scale responsive
  double _scale(double size) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return size * 1.3;
    if (width > 400) return size * 1.1;
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.04;
    final cardSpacing = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          "Chủ đề nhập vai",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: _scale(20),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: topicViewModel.fetchTopics,
        child: Obx(() {
          if (topicViewModel.isLoadingTopics.value && topicViewModel.topics.isEmpty) {
            return const Center(child: CupertinoActivityIndicator(radius: 15));
          }

          if (topicViewModel.topics.isEmpty) {
            return Center(
              child: ListView(
                children: [
                  SizedBox(height: screenHeight * 0.3),
                  Icon(CupertinoIcons.bubble_left_bubble_right,
                      size: _scale(60), color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Chưa có chủ đề nào",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: _scale(17), color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final topics = topicViewModel.topics;
          return Padding(
            padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 16), // ← DÒNG QUAN TRỌNG
            child: GridView.builder(
              padding: EdgeInsets.all(horizontalPadding),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return _buildTopicCard(topic, index, _scale);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopicCard(TopicModel topic, int index, Function(double) scale) {
    return GestureDetector(
      onTap: () async {
        await Get.to(
              () => ConfirmContextScreen(topic: topic),
          transition: Transition.cupertino,
        );
        // Khi quay lại từ ConfirmContextScreen, cập nhật lại số lượt luyện tập
        topicViewModel.fetchConversationUsage();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(scale(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: scale(10),
              offset: Offset(0, scale(5)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(scale(20)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // === BACKGROUND IMAGE ===
              Image.network(
                topic.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: Icon(
                      CupertinoIcons.photo,
                      size: scale(50),
                      color: Colors.grey.shade500,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CupertinoActivityIndicator(radius: scale(10)),
                    ),
                  );
                },
              ),

              // === GRADIENT OVERLAY ===
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),

              // === CONTENT ===
              Padding(
                padding: EdgeInsets.all(scale(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === TIÊU ĐỀ ===
                    Text(
                      topic.topicName,
                      style: TextStyle(
                        fontSize: scale(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: scale(8)),

                    // === MÔ TẢ ===
                    Expanded(
                      child: Text(
                        topic.topicDescription,
                        style: TextStyle(
                          fontSize: scale(13.5),
                          color: Colors.white.withOpacity(0.95),
                          height: 1.35,
                          shadows: const [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            )
                          ],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    SizedBox(height: scale(8)),

                    // === ICON ARROW ===
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.all(scale(8)),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.arrow_right,
                          color: Colors.white,
                          size: scale(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}