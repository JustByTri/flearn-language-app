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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppScaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textLight),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
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
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return _buildTopicCard(topic, index);
              },
            ),
          );
        }),
        bottomNavigationBar: MainBottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                break;
              case 1:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TopicScreen()));
                break;
              case 2:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CourseScreen()));
                break;
              case 3:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildTopicCard(TopicModel topic, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ConfirmContextScreen(topic: topic)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [

              _buildCardBackground(topic, index),


              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),


              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    topic.topicName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardBackground(TopicModel topic, int index) {

    if (topic.imageUrl != "default" &&
        topic.imageUrl.isNotEmpty &&
        Uri.tryParse(topic.imageUrl) != null) {
      return Image.network(
        topic.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildColorBackground(topic);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildColorBackground(topic);
        },
      );
    } else {
      return _buildColorBackground(topic);
    }
  }

  Widget _buildColorBackground(TopicModel topic) {
    final hash = topic.topicId.hashCode.abs();
    final hue1 = (hash % 360).toDouble();
    final hue2 = ((hash + 60) % 360).toDouble();

    final color1 = HSVColor.fromAHSV(1.0, hue1, 0.7, 0.8).toColor();
    final color2 = HSVColor.fromAHSV(1.0, hue2, 0.6, 0.9).toColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
      ),
    );
  }
}