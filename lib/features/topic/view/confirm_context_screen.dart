import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../auth/view/subcription_plans.dart';
import '../model/conversationLanguage.dart';
import '../model/topic.dart';
import '../viewmodel/topic_viewmodel.dart';
import 'chatAi_screen.dart';

// --- Coursera/Enterprise Style Constants ---
const Color kCourseraBlue = Color(0xFF0056D2);
const Color kBackgroundColor = Colors.white;
const Color kTextPrimary = Color(0xFF1F1F1F);
const Color kTextSecondary = Color(0xFF5E5E5E);
const Color kCardBorderColor = Color(0xFFE0E0E0);
const double kCardRadius = 12.0;

class ConfirmContextScreen extends StatefulWidget {
  final TopicModel topic;
  const ConfirmContextScreen({
    super.key,
    required this.topic,
  });

  @override
  State<ConfirmContextScreen> createState() =>
      _ConfirmContextScreenState();
}

class _ConfirmContextScreenState
    extends State<ConfirmContextScreen>
    with WidgetsBindingObserver {
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
      topicViewModel.fetchConversationLevels(langId).then((
          _,
          ) {
        if (mounted) {
          final levels = _getAvailableLevels();
          setState(() {
            _selectedLevel = levels.isNotEmpty
                ? levels.first.levelName
                : null;
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
        _conversationsUsedToday =
        usage?['conversationsUsedToday'];
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
      backgroundColor: kCourseraBlue,
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
      final langId = GetStorage().read(
        'user',
      )?['languageId'];
      if (langId == null) {
        throw Exception('Chưa chọn ngôn ngữ.');
      }
      final topicViewModel = Get.find<TopicViewModel>();
      final conversationData = await topicViewModel
          .startConversation(
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
        throw Exception(
          'Không thể bắt đầu cuộc trò chuyện.',
        );
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
      return WillPopScope(
        onWillPop: () async {
          _isConfirmDialogOpen = true;
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text('Xác nhận'),
              content: const Text(
                'Bạn có chắc muốn thoát không?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _isConfirmDialogOpen = false;
                    Navigator.of(context).pop(false);
                  },
                  child: const Text(
                    'Không',
                    style: TextStyle(color: kTextSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _isConfirmDialogOpen = false;
                    _isCancelled = true;
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    'Có',
                    style: TextStyle(
                      color: kCourseraBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Có thể thay bằng CircularProgressIndicator màu xanh nếu không muốn dùng gif
                  Image.asset(
                    'assets/images/animationAI2.gif',
                    width: 150,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Đang khởi tạo hội thoại...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AI đang chuẩn bị kịch bản phù hợp nhất dành cho bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _buildUsageInfo(),
                  const SizedBox(height: 32),
                  const Text(
                    "Chọn trình độ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Chọn mức độ phù hợp với khả năng hiện tại của bạn.",
                    style: TextStyle(
                      fontSize: 14,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLevelSelector(),
                  const SizedBox(height: 40),
                  _buildStartButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.topic.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              child: const Icon(
                Icons.image,
                size: 50,
                color: Colors.grey,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CHỦ ĐỀ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.topic.topicName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.topic.topicDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageInfo() {
    if (_isCheckingUsage) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: kCardBorderColor),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_dailyLimit != null &&
        _conversationsUsedToday != null) {
      final remaining =
          _dailyLimit! - _conversationsUsedToday!;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: kCardBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kCourseraBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt,
                color: kCourseraBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lượt thực hành hôm nay',
                    style: TextStyle(
                      fontSize: 13,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      text: '$remaining',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: '/$_dailyLimit',
                          style: const TextStyle(
                            fontSize: 14,
                            color: kTextSecondary,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLevelSelector() {
    return Obx(() {
      final topicViewModel = Get.find<TopicViewModel>();
      if (topicViewModel.isLoadingLevels.value)
        return const Center(
          child: CupertinoActivityIndicator(),
        );

      final levels = _getAvailableLevels();
      if (levels.isEmpty)
        return const Text(
          "Không có trình độ nào.",
          style: TextStyle(color: kTextSecondary),
        );

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: levels.map((level) {
          final isSelected =
              _selectedLevel == level.levelName;
          return GestureDetector(
            onTap: () => setState(
                  () => _selectedLevel = level.levelName,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? kCourseraBlue.withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? kCourseraBlue
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                level.levelName,
                style: TextStyle(
                  color: isSelected
                      ? kCourseraBlue
                      : kTextPrimary,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildStartButton() {
    final isQuotaExceeded =
    (_dailyLimit != null &&
        _conversationsUsedToday != null)
        ? _conversationsUsedToday! >= _dailyLimit!
        : false;

    if (isQuotaExceeded) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () async {
            final result = await Get.to(
                  () => const SubscriptionPlansScreen(),
            );
            if (result == true) {
              await _fetchConversationUsage();
              Get.snackbar(
                "Thành công",
                "Đã mua thêm lượt!",
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            "Mua thêm lượt",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () async {
          setState(() => _isLoading = true);
          await _startConversation();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: kCourseraBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const CupertinoActivityIndicator(
          color: Colors.white,
        )
            : const Text(
          "Bắt đầu luyện tập",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
