import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:get/get.dart';

import '../model/topic.dart';
import '../viewmodel/topic_viewmodel.dart';
import 'confirm_context_screen.dart';

// Coursera style constants
const Color kCourseraBlue = Color(0xFF0056D2);
const Color kCardBorderColor = Color(0xFFE0E0E0);
const double kCardRadius = 12.0; // Giảm từ 24 xuống 12

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
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + 20;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      extendBody: true,
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

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              _scale(20),
              horizontalPadding,
              bottomPadding,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
          borderRadius: BorderRadius.circular(kCardRadius), // Bo góc vừa phải 12
          border: Border.all(color: kCardBorderColor), // Thêm viền mỏng
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
          borderRadius: BorderRadius.circular(kCardRadius),
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

                      // Arrow Button - đơn giản như trong hình
                      Container(
                        width: scale(32),
                        height: scale(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD), // Xanh nhạt
                          borderRadius: BorderRadius.circular(scale(8)), // Bo góc nhẹ
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.arrow_right,
                            color: const Color(0xFF2196F3), // Xanh đậm hơn
                            size: scale(18), // Tăng size từ 16 lên 18
                            weight: 600, // Thêm weight để đậm hơn
                          ),
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