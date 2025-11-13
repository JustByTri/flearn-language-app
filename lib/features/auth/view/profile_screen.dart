import 'package:flearn_app/di.dart';
import 'package:flearn_app/features/auth/view/change_password_screen.dart';
import 'package:flearn_app/features/auth/view/edit_profile_screen.dart';
import 'package:flearn_app/features/auth/view/subcription_plans.dart';
import 'package:flearn_app/features/schedule/view/schedule_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flearn_app/core/constants/colors.dart';
import '../view/login_screen.dart';
import '../viewmodel/login_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';
import '../../../shared/widgets/app_scaffold.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserViewModel userViewModel;
  final loginViewModel = Get.find<LoginViewModel>();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<UserViewModel>()) {
      userViewModel = Get.find<UserViewModel>();
    } else {
      userViewModel = Get.put(UserViewModel(Get.find()), permanent: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserProfile();
    });
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

      return Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                // Avatar centered
                GestureDetector(
                  onTap: () => Get.to(
                    () => const EditProfileScreen(),
                    arguments: userViewModel.user.value,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
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
                () => const ScheduleScreen(),
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
              Get.snackbar(
                'Thông báo',
                'Tính năng đang được phát triển',
                snackPosition: SnackPosition.BOTTOM,
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
}

// Custom Painter để vẽ đường cong wave
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4A90E2), Color(0xFF5AB0FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.lineTo(0, size.height - 60);

    // Vẽ đường cong wave
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 20,
      size.width * 0.5,
      size.height - 40,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 60,
      size.width,
      size.height - 20,
    );

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}