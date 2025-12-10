import 'package:flearn_app/di.dart';
import 'package:flearn_app/features/auth/view/edit_profile_screen.dart';
import 'package:flearn_app/features/auth/view/purchase_history_screen.dart';
import 'package:flearn_app/features/auth/view/refund_center_screen.dart';
import 'package:flearn_app/features/auth/view/subcription_plans.dart';
import 'package:flearn_app/features/gamification/view/daily_goal_screen.dart';
import 'package:flearn_app/features/gamification/view/leaderboard_screen.dart';
import 'package:flearn_app/features/gamification/viewmodel/gamification_viewmodel.dart';
import 'package:flearn_app/features/schedule/view/student_schedule_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../schedule/viewmodel/schedule_viewmodel.dart';
import '../../topic/viewmodel/topic_viewmodel.dart';
import '../view/login_screen.dart';
import '../viewmodel/login_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';

// --- Coursera Style Constants ---
const Color kCourseraBlue = Color(0xFF0056D2);
const Color kBackgroundColor = Colors.white;
const Color kTextPrimary = Color(0xFF1F1F1F);
const Color kTextSecondary = Color(0xFF5E5E5E);
const double kAvatarRadius = 50.0;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  late final UserViewModel userViewModel;
  final loginViewModel = Get.find<LoginViewModel>();
  ScheduleViewModel? scheduleViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Get.isRegistered<ScheduleViewModel>()) {
      scheduleViewModel = Get.find<ScheduleViewModel>();
    } else {
      scheduleViewModel = Get.put(
        ScheduleViewModel(service: Get.find()),
        permanent: true,
      );
    }
    if (Get.isRegistered<UserViewModel>()) {
      userViewModel = Get.find<UserViewModel>();
    } else {
      userViewModel = Get.put(
        UserViewModel(Get.find()),
        permanent: true,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fetchUserProfile();
      final topicVM = Get.isRegistered<TopicViewModel>()
          ? Get.find<TopicViewModel>()
          : Get.put(
        TopicViewModel(Get.find()),
        permanent: true,
      );
      await topicVM.fetchConversationUsage();
      await scheduleViewModel?.fetchMyEnrollments();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final topicVM = Get.isRegistered<TopicViewModel>()
          ? Get.find<TopicViewModel>()
          : Get.put(
        TopicViewModel(Get.find()),
        permanent: true,
      );
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
    Get.offAll(
          () => const LoginScreen(),
      transition: Transition.rightToLeftWithFade,
    );
  }

  Future<void> _showLogoutConfirmation() async {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text("Đăng xuất"),
        content: const Text(
          "Bạn có chắc chắn muốn đăng xuất không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Huỷ",
              style: TextStyle(color: kTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
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
      final refreshToken = GetStorage().read(
        'refreshToken',
      );
      if (refreshToken != null) {
        await loginViewModel.logoutApi(refreshToken);
      }
      loginViewModel.logout();
      Get.snackbar(
        "Đã đăng xuất",
        "Hẹn gặp lại bạn nhé!",
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AppScaffold(
        backgroundColor: kBackgroundColor,
        body: RefreshIndicator(
          onRefresh: _fetchUserProfile,
          color: kCourseraBlue,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(
                  height: 1,
                  color: Color(0xFFEEEEEE),
                ),
                _buildMenuSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final user = userViewModel.user.value;
      final avatarUrl = user?.avatar;
      final displayName =
      (user?.fullname?.isNotEmpty == true)
          ? user!.fullname!
          : (user?.username ?? 'Học viên');
      final email = user?.email ?? "";

      final topicVM = Get.isRegistered<TopicViewModel>()
          ? Get.find<TopicViewModel>()
          : Get.put(
        TopicViewModel(Get.find()),
        permanent: true,
      );
      final usage = topicVM.conversationUsage.value;
      final type = (usage?['subscriptionType'] ?? 'free')
          .toString()
          .toLowerCase();

      String packageLabel = 'Gói miễn phí';
      if (type.contains('basic'))
        packageLabel = 'Thành viên Pro';

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
        color: Colors.white,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Get.to(
                    () => const EditProfileScreen(),
                arguments: userViewModel.user.value,
              ),
              child: _buildRankedAvatar(avatarUrl),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kCourseraBlue.withOpacity(
                            0.1,
                          ),
                          borderRadius:
                          BorderRadius.circular(4),
                        ),
                        child: Text(
                          packageLabel,
                          style: const TextStyle(
                            color: kCourseraBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (type != 'basic15')
                        GestureDetector(
                          onTap: () async {
                            List<String> availablePlans =
                            [];
                            if (type == 'free')
                              availablePlans = [
                                'basic5',
                                'basic10',
                                'basic15',
                              ];
                            else if (type == 'basic5')
                              availablePlans = [
                                'basic10',
                                'basic15',
                              ];
                            else if (type == 'basic10')
                              availablePlans = ['basic15'];

                            final result = await Get.to<bool>(
                                  () => SubscriptionPlansScreen(
                                availablePlans:
                                availablePlans,
                              ),
                            );
                            if (result == true) {
                              await topicVM
                                  .fetchConversationUsage();
                              if (mounted) setState(() {});
                            }
                          },
                          child: const Text(
                            'Nâng cấp',
                            style: TextStyle(
                              color: kCourseraBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              decoration:
                              TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Học tập'),
          _buildMenuItem(
            icon: CupertinoIcons.calendar,
            title: 'Lịch học của tôi',
            onTap: () =>
                Get.to(() => const StudentScheduleScreen()),
          ),
          _buildMenuItem(
            icon: CupertinoIcons.scope,
            title: 'Mục tiêu hàng ngày',
            onTap: () =>
                Get.to(() => const DailyGoalScreen()),
          ),
          _buildMenuItem(
            icon: CupertinoIcons.chart_bar_alt_fill,
            title: 'Bảng xếp hạng',
            onTap: () =>
                Get.to(() => const LeaderboardScreen()),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Tài khoản'),
          _buildMenuItem(
            icon: CupertinoIcons.person,
            title: 'Chỉnh sửa hồ sơ',
            onTap: () => Get.to(
                  () => const EditProfileScreen(),
              arguments: userViewModel.user.value,
            ),
          ),
          _buildMenuItem(
            icon: CupertinoIcons.doc_text,
            title: 'Lịch sử thanh toán',
            onTap: () =>
                Get.to(() => const PurchaseHistoryScreen()),
          ),
          _buildMenuItem(
            icon: CupertinoIcons.mail,
            title: 'Trung tâm hỗ trợ / Hoàn tiền',
            onTap: () =>
                Get.to(() => const RefundCenterScreen()),
          ),

          const SizedBox(height: 24),
          _buildMenuItem(
            icon: CupertinoIcons.square_arrow_right,
            title: 'Đăng xuất',
            textColor: Colors.redAccent,
            iconColor: Colors.redAccent,
            showArrow: false,
            onTap: _showLogoutConfirmation,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: kTextSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = kTextPrimary,
    Color iconColor = kTextSecondary,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (showArrow)
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankedAvatar(String? avatarUrl) {
    final gamificationVM =
    Get.isRegistered<GamificationViewModel>()
        ? Get.find<GamificationViewModel>()
        : null;
    final userRank =
        gamificationVM?.userRank.value?.rank ?? 0;
    final isTopRank = userRank > 0 && userRank <= 3;

    Color borderColor = Colors.transparent;
    if (userRank == 1)
      borderColor = const Color(0xFFFFD700);
    else if (userRank == 2)
      borderColor = const Color(0xFFC0C0C0);
    else if (userRank == 3)
      borderColor = const Color(0xFFCD7F32);

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isTopRank
                ? Border.all(color: borderColor, width: 2)
                : null,
          ),
          child: CircleAvatar(
            radius: kAvatarRadius,
            backgroundColor: Colors.grey.shade100,
            backgroundImage:
            (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Icon(
              CupertinoIcons.person_fill,
              color: Colors.grey.shade300,
              size: 40,
            )
                : null,
          ),
        ),
        if (isTopRank)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: borderColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }
}
