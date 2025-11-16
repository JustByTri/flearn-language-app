import 'package:flearn_app/di.dart';
import 'package:flearn_app/features/auth/view/change_password_screen.dart';
import 'package:flearn_app/features/auth/view/edit_profile_screen.dart';
import 'package:flearn_app/features/auth/view/purchase_history_screen.dart';
import 'package:flearn_app/features/auth/view/subcription_plans.dart';
import 'package:flearn_app/features/schedule/view/schedule_screen.dart';
import 'package:flearn_app/features/schedule/view/student_schedule_screen.dart';
import 'package:flearn_app/features/gamification/view/daily_goal_screen.dart';
import 'package:flearn_app/features/gamification/view/leaderboard_screen.dart';
import 'package:flearn_app/features/gamification/viewmodel/gamification_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flearn_app/core/constants/colors.dart';
import '../../topic/viewmodel/topic_viewmodel.dart';
import '../view/login_screen.dart';
import '../viewmodel/login_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';
import '../../../shared/widgets/app_scaffold.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  late final UserViewModel userViewModel;
  final loginViewModel = Get.find<LoginViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Đăng ký observer
    if (Get.isRegistered<UserViewModel>()) {
      userViewModel = Get.find<UserViewModel>();
    } else {
      userViewModel = Get.put(UserViewModel(Get.find()), permanent: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fetchUserProfile();
      final topicVM = Get.isRegistered<TopicViewModel>()
          ? Get.find<TopicViewModel>()
          : Get.put(TopicViewModel(Get.find()), permanent: true);
      await topicVM.fetchConversationUsage();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Hủy observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.resumed) {
      final topicVM = Get.isRegistered<TopicViewModel>()
          ? Get.find<TopicViewModel>()
          : Get.put(TopicViewModel(Get.find()), permanent: true);
      topicVM.fetchConversationUsage();
      _fetchUserProfile();
      setState(() {});
    }
  }

  Future<void> _fetchUserProfile() async {
    await userViewModel.fetchUserInfo();
  }

  void _navigateToLogin() {
    Get.deleteAll(force: true);
    setupDI();
    Get.offAll(() => const LoginScreen(), transition: Transition.rightToLeftWithFade);
  }

  Future<void> _showLogoutConfirmation() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Huỷ"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              _logout();
            },
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final refreshToken = GetStorage().read('refreshToken');
      if (refreshToken != null) {
        await loginViewModel.logoutApi(refreshToken);
      }
      loginViewModel.logout();

      Get.snackbar(
        "Đã đăng xuất",
        "Hẹn gặp lại bạn nhé!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );

      _navigateToLogin();
    } catch (e) {
      loginViewModel.logout();
      _navigateToLogin();
      debugPrint("Lỗi đăng xuất: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchUserProfile,
        edgeOffset: 100.0,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeaderWithAvatar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                child: _buildFunctionList(),
              ),
              const SizedBox(height: kBottomNavigationBarHeight + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithAvatar() {
    return Obx(() {
      final user = userViewModel.user.value;
      final avatarUrl = user?.avatar;
      final displayName = (user?.fullname != null && user!.fullname!.isNotEmpty)
          ? user.fullname!
          : (user?.username ?? 'Đang tải...');
      final email = user?.email ?? "";


      final topicVM = Get.isRegistered<TopicViewModel>()
          ? Get.find<TopicViewModel>()
          : Get.put(TopicViewModel(Get.find()), permanent: true);
      final usage = topicVM.conversationUsage.value;
      String packageName = '';
      final type = (usage?['subscriptionType'] ?? 'free').toString().toLowerCase();
      switch (type) {
        case 'free':
          packageName = 'Gói nhập vai: miễn phí';
          break;
        case 'basic5':
          packageName = 'Gói nhập vai: gói tiết kiệm 5';
          break;
        case 'basic10':
          packageName = 'Gói nhập vai: gói cơ bản 10';
          break;
        case 'basic15':
          packageName = 'Gói nhập vai: gói nâng cao';
          break;
        default:
          packageName = 'Gói nhập vai: $type';
      }

      return Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Get.to(
                        () => const EditProfileScreen(),
                    arguments: userViewModel.user.value,
                  ),
                  child: _buildRankedAvatar(avatarUrl),
                ),
                const SizedBox(height: 16),
                // Display Name
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Package info with better UI
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.sparkles,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          packageName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Upgrade button with solid gold color (no gradient/shadow)
                Container(
                  width: 160,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700), // vàng phẳng
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        if (type == 'basic15') {
                          Get.snackbar(
                            'Thông báo',
                            'Bạn đã nâng lên gói cao nhất.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        List<String> availablePlans = [];
                        if (type == 'free') {
                          availablePlans = ['basic5', 'basic10', 'basic15'];
                        } else if (type == 'basic5') {
                          availablePlans = ['basic10', 'basic15'];
                        } else if (type == 'basic10') {
                          availablePlans = ['basic15'];
                        }

                        final result = await Get.to<bool>(
                              () => SubscriptionPlansScreen(availablePlans: availablePlans),
                          transition: Transition.cupertino,
                        );

                        if (result == true) {
                          final topicVM = Get.isRegistered<TopicViewModel>()
                              ? Get.find<TopicViewModel>()
                              : Get.put(TopicViewModel(Get.find()), permanent: true);
                          await topicVM.fetchConversationUsage();
                          if (mounted) setState(() {});
                        }
                      },
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type == 'basic15'
                                  ? CupertinoIcons.checkmark_seal_fill
                                  : CupertinoIcons.arrow_up_circle_fill,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              type == 'basic15' ? 'Gói cao nhất' : 'Nâng cấp',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFunctionList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: CupertinoIcons.person_circle,
            label: "Chỉnh sửa hồ sơ",
            iconColor: const Color(0xFF4A90E2),
            onTap: () => Get.to(
                  () => const EditProfileScreen(),
              arguments: userViewModel.user.value,
            ),
          ),
          _buildDivider(),
          _buildListTile(
            icon: CupertinoIcons.calendar,
            label: "Lịch học",
            iconColor: const Color(0xFF34C759),
            onTap: () {
              Get.to(
                () => const StudentScheduleScreen(),
                transition: Transition.cupertino,
              );
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: CupertinoIcons.chart_bar,
            label: "Mục tiêu học tập",
            iconColor: const Color(0xFFFF9500),
            onTap: () {
              Get.to(
                () => const DailyGoalScreen(),
                transition: Transition.cupertino,
              );
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: CupertinoIcons.chart_bar_alt_fill,
            label: "Bảng xếp hạng",
            iconColor: const Color(0xFFFFD700),
            onTap: () {
              Get.to(
                () => const LeaderboardScreen(),
                transition: Transition.cupertino,
              );
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: CupertinoIcons.doc_text,
            label: "Lịch sử giao dịch",
            iconColor: const Color(0xFF4A90E2),
            onTap: () {
              Get.to(
                    () => const PurchaseHistoryScreen(),
                transition: Transition.cupertino,
              );
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: CupertinoIcons.arrow_right_square,
            label: "Đăng xuất",
            iconColor: const Color(0xFFFF3B30),
            onTap: _showLogoutConfirmation,
            showArrow: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (showArrow)
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankedAvatar(String? avatarUrl) {
    // Get user rank from GamificationViewModel
    final gamificationVM = Get.isRegistered<GamificationViewModel>()
        ? Get.find<GamificationViewModel>()
        : null;

    final userRank = gamificationVM?.userRank.value?.rank ?? 0;
    final isTopRank = userRank > 0 && userRank <= 3;

    Color? frameColor;
    Color? glowColor;

    if (userRank == 1) {
      frameColor = Color(0xFFFFD700); // Gold
      glowColor = Color(0xFFFFD700);
    } else if (userRank == 2) {
      frameColor = Color(0xFFC0C0C0); // Silver
      glowColor = Color(0xFFC0C0C0);
    } else if (userRank == 3) {
      frameColor = Color(0xFFCD7F32); // Bronze
      glowColor = Color(0xFFCD7F32);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isTopRank
                ? LinearGradient(
                    colors: [frameColor!, frameColor.withAlpha(200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: isTopRank
                    ? glowColor!.withAlpha(100)
                    : Colors.black.withAlpha(25),
                blurRadius: isTopRank ? 20 : 15,
                spreadRadius: isTopRank ? 3 : 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: isTopRank ? const EdgeInsets.all(5) : EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            padding: isTopRank ? const EdgeInsets.all(4) : EdgeInsets.zero,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.grey.shade400,
                      size: 50,
                    )
                  : null,
            ),
          ),
        ),
        if (isTopRank)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [frameColor!, frameColor.withAlpha(220)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: glowColor!.withAlpha(150),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}
