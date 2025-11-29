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
      topicViewModel.fetchConversationUsage();
    }
  }

  double _scale(double size) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return size * 1.3;
    if (width > 400) return size * 1.1;
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Chủ đề nhập vai",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: _scale(21),
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                  Colors.grey.shade200,
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: topicViewModel.fetchTopics,
        color: AppColors.textPrimary,
        child: Obx(() {
          if (topicViewModel.isLoadingTopics.value && topicViewModel.topics.isEmpty) {
            return const Center(child: CupertinoActivityIndicator(radius: 15));
          }

          if (topicViewModel.topics.isEmpty) {
            return Center(
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Container(
                    padding: EdgeInsets.all(_scale(24)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.chat_bubble_2,
                      size: _scale(64),
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Chưa có chủ đề nào",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _scale(18),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Kéo xuống để làm mới",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _scale(14),
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 20),
            child: GridView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: _scale(20),
              ),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.82,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: topicViewModel.topics.length,
              itemBuilder: (context, index) {
                final topic = topicViewModel.topics[index];
                return _buildTopicCard(topic, _scale);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopicCard(TopicModel topic, Function(double) scale) {
    return GestureDetector(
      onTap: () async {
        await Get.to(
              () => ConfirmContextScreen(topic: topic),
          transition: Transition.cupertino,
        );
        topicViewModel.fetchConversationUsage();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(scale(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: scale(20),
              offset: Offset(0, scale(4)),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: scale(8),
              offset: Offset(0, scale(2)),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(scale(24)),
          child: Column(
            children: [
              // ───────────── IMAGE WITH GRADIENT OVERLAY ─────────────
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.55,
                    child: Image.network(
                      topic.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.shade100,
                              Colors.grey.shade200,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.photo_on_rectangle,
                            size: scale(48),
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      loadingBuilder: (_, __, progress) => progress == null
                          ? Image.network(topic.imageUrl, fit: BoxFit.cover)
                          : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade50,
                              Colors.grey.shade100,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      ),
                    ),
                  ),
                  // Subtle gradient overlay for better text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ───────────── CONTENT SECTION ─────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    scale(16),
                    scale(14),
                    scale(14),
                    scale(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      Expanded(
                        child: Text(
                          topic.topicName,
                          style: TextStyle(
                            fontSize: scale(13.5),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                            height: 1.4,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(width: scale(10)),

                      // Arrow Button with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: scale(32),
                        height: scale(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(scale(18)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D3142).withOpacity(0.3),
                              blurRadius: scale(8),
                              offset: Offset(0, scale(3)),
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.arrow_right,
                          color: Colors.white,
                          size: scale(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}