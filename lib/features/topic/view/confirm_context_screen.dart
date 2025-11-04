import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/constants/colors.dart';
import '../model/conversationLanguage.dart';
import '../model/topic.dart';
import '../viewmodel/topic_viewmodel.dart';
import 'chatAi_screen.dart';

class ConfirmContextScreen extends StatefulWidget {
  final TopicModel topic;
  const ConfirmContextScreen({super.key, required this.topic});

  @override
  State<ConfirmContextScreen> createState() => _ConfirmContextScreenState();
}

class _ConfirmContextScreenState extends State<ConfirmContextScreen> {
  String? _selectedLevel;
  bool _isLoading = false;

  List<LanguageLevel> _getAvailableLevels() {
    final topicViewModel = Get.find<TopicViewModel>();
    return topicViewModel.conversationLevels;
  }

  @override
  void initState() {
    super.initState();
    final topicViewModel = Get.find<TopicViewModel>();
    final langId = GetStorage().read('user')?['languageId'];
    if (langId != null) {
      topicViewModel.fetchConversationLevels(langId).then((_) {
        if (mounted) {
          final levels = _getAvailableLevels();
          setState(() {
            _selectedLevel = levels.isNotEmpty ? levels.first.levelName : null;
          });
        }
      });
    }
  }

  Future<void> _startConversation() async {
    final levels = _getAvailableLevels();
    if (_selectedLevel == null && levels.isNotEmpty) {
      _selectedLevel = levels.first.levelName;
    }
    if (_selectedLevel == null) {
      Get.snackbar(
        "Lỗi",
        "Không tìm thấy trình độ cho ngôn ngữ hiện tại.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final langId = GetStorage().read('user')?['languageId'];
      if (langId == null) {
        throw Exception('Chưa chọn ngôn ngữ.');
      }
      final topicViewModel = Get.find<TopicViewModel>();
      final conversationData = await topicViewModel.startConversation(
        languageId: langId,
        topicId: widget.topic.topicId,
        difficultyLevel: _selectedLevel!,
      );

      if (!mounted) return;

      if (conversationData != null) {
        Get.off(
              () => ChatScreen(
            topic: widget.topic,
            conversationData: conversationData,
          ),
          transition: Transition.cupertino,
        );
      } else {
        throw Exception('Không thể bắt đầu cuộc trò chuyện.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar(
          "Lỗi",
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white, // <--- SỬA MÀU NỀN
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/animationAI.gif', width: 180),
              const SizedBox(height: 30),
              Text(
                'Đợi chút nhé, tớ đang suy nghĩ...\nKịch bản sắp được tạo cho bạn trong giây lát.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary, height: 1.5), // <--- SỬA MÀU CHỮ
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Bỏ nút back tự động
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Chọn trình độ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                _buildLevelSelector(),
                const Spacer(),
                _buildStartButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: Get.height * 0.4,
      width: double.infinity,
      decoration: BoxDecoration(
        // Bỏ gradient cũ
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // === BACKGROUND IMAGE ===
          Image.network(
            widget.topic.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade400,
                child: const Icon(
                  CupertinoIcons.photo,
                  size: 80,
                  color: Colors.white54,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: CupertinoActivityIndicator(),
                ),
              );
            },
          ),

          // === GRADIENT OVERLAY ===
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // === CONTENT ===
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topic.topicName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.topic.topicDescription,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.5,
                    shadows: const [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      )
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Obx(() {
      final topicViewModel = Get.find<TopicViewModel>();
      if (topicViewModel.isLoadingLevels.value) {
        return const Center(child: CupertinoActivityIndicator());
      }
      final levels = _getAvailableLevels();
      if (levels.isEmpty) {
        return const Text("Không có trình độ nào cho ngôn ngữ này.");
      }
      return Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: levels.map((level) {
          final isSelected = _selectedLevel == level.levelName;
          return ChoiceChip(
            label: Text(level.levelName),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedLevel = level.levelName;
                }
              });
            },
            backgroundColor: Colors.grey.shade100,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
            ),
            showCheckmark: false,
          );
        }).toList(),
      );
    });
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _startConversation,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: const Text(
          "Bắt đầu luyện tập",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
