import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/constants/colors.dart';
import '../../auth/view/subcription_plans.dart';
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

class _ConfirmContextScreenState extends State<ConfirmContextScreen> with WidgetsBindingObserver {
  String? _selectedLevel;
  bool _isLoading = false;
  int? _dailyLimit;
  int? _conversationsUsedToday;
  bool _isCheckingUsage = true;
  bool _isConfirmDialogOpen = false;
  bool _isCancelled = false;

  List<LanguageLevel> _getAvailableLevels() {
    final topicViewModel = Get.find<TopicViewModel>();
    return topicViewModel.conversationLevels;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _fetchConversationUsage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchConversationUsage();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchConversationUsage();
  }

  Future<void> _fetchConversationUsage() async {
    setState(() => _isCheckingUsage = true);
    try {
      final topicViewModel = Get.find<TopicViewModel>();
      await topicViewModel.fetchConversationUsage();
      final usage = topicViewModel.conversationUsage.value;
      setState(() {
        _dailyLimit = usage?['dailyLimit'];
        _conversationsUsedToday = usage?['conversationsUsedToday'];
        _isCheckingUsage = false;
      });
    } catch (e) {
      setState(() => _isCheckingUsage = false);
    }
  }

  Future<void> _startConversation() async {
    Get.snackbar(
      "Thông báo",
      "Bạn đã dùng 1 lượt luyện tập.",
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );

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

      await _fetchConversationUsage();

      if (!mounted) return;

      if (conversationData != null) {
        if (!_isConfirmDialogOpen && !_isCancelled) {
          Get.off(
                () => ChatScreen(
              topic: widget.topic,
              conversationData: conversationData,
            ),
            transition: Transition.cupertino,
          );
        }
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    if (_isLoading) {
      return WillPopScope(
        onWillPop: () async {
          _isConfirmDialogOpen = true;
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Xác nhận'),
              content: const Text('Bạn có chắc muốn thoát không?'),
              actions: [
                TextButton(
                  onPressed: () {
                    _isConfirmDialogOpen = false;
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Không'),
                ),
                TextButton(
                  onPressed: () {
                    _isConfirmDialogOpen = false;
                    _isCancelled = true;
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Có'),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            Get.back();
          }
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/animationAI2.gif', width: 180),
                const SizedBox(height: 30),
                Text(
                  'Đợi chút nhé, tớ đang suy nghĩ...\nKịch bản sắp được tạo cho bạn trong giây lát.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: AppColors.textPrimary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(screenSize, isSmallScreen),
    );
  }

  Widget _buildHeader(Size screenSize, bool isSmallScreen) {
    return Container(
      height: screenSize.height * 0.42,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            widget.topic.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade400,
                    ],
                  ),
                ),
                child: const Icon(CupertinoIcons.photo, size: 80, color: Colors.white54),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade200,
                child: const Center(child: CupertinoActivityIndicator()),
              );
            },
          ),

          // Dark Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 60, 24, isSmallScreen ? 25 : 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.topic.topicName,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.topic.topicDescription,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Size screenSize, bool isSmallScreen) {
    return Column(
      children: [
        _buildHeader(screenSize, isSmallScreen),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 24, vertical: isSmallScreen ? 14 : 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Usage Info Card
                if (_isCheckingUsage)
                  _buildUsageCard(
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
                  )
                else if (_dailyLimit != null && _conversationsUsedToday != null)
                  _buildUsageCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.chart_bar_alt_fill,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lượt luyện tập hôm nay',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_dailyLimit! - _conversationsUsedToday!} / $_dailyLimit',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: isSmallScreen ? 15 : 25),

                // Level Selection Section
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.star_circle_fill,
                      color: AppColors.primary,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Chọn trình độ",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Chọn mức độ phù hợp với khả năng của bạn",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),

                _buildLevelSelector(isSmallScreen),
                const Spacer(),
                _buildStartButton(isSmallScreen),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLevelSelector(bool isSmallScreen) {
    return Obx(() {
      final topicViewModel = Get.find<TopicViewModel>();
      if (topicViewModel.isLoadingLevels.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CupertinoActivityIndicator(),
          ),
        );
      }
      final levels = _getAvailableLevels();
      if (levels.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Text(
              "Không có trình độ nào cho ngôn ngữ này.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        );
      }
      return Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: levels.map((level) {
          final isSelected = _selectedLevel == level.levelName;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedLevel = level.levelName;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 24, vertical: isSmallScreen ? 12 : 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Text(
                level.levelName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildStartButton(bool isSmallScreen) {
    final isQuotaExceeded = (_dailyLimit != null && _conversationsUsedToday != null)
        ? _conversationsUsedToday! >= _dailyLimit!
        : false;

    if (_isLoading) {
      return SizedBox(
        width: double.infinity,
        height: isSmallScreen ? 48 : 56,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const CupertinoActivityIndicator(color: Colors.white),
        ),
      );
    }

    if (isQuotaExceeded) {
      return SizedBox(
        width: double.infinity,
        height: isSmallScreen ? 48 : 56,
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
            );
            if (result == true) {
              await _fetchConversationUsage();
              Get.snackbar(
                "Thành công",
                "Bạn đã mua lượt luyện tập thành công!",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            "Mua lượt luyện tập",
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 48 : 56,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
          setState(() => _isLoading = true);
          await _startConversation();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Text(
          "Bắt đầu luyện tập",
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
