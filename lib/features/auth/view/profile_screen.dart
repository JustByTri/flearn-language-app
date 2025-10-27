import 'package:flearn_app/features/auth/view/change_password_screen.dart';
import 'package:flearn_app/features/auth/view/edit_profile_screen.dart';
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
      backgroundColor: Colors.grey.shade50,
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
      final username = user?.username ?? "";
      final email = user?.email ?? "";
      final role = user?.roles?.isNotEmpty == true ? user!.roles!.first : '';

      return SizedBox(
        height: 340,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background gradient với wave curve
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 240),
              painter: WavePainter(),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Avatar
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
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 56,
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
                  ),
                  const SizedBox(height: 14),
                  // Display Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 0.7,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Username & Role
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.at,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (role.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: Color(0xFF4A90E2),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Email
                  Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.mail_solid,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    });
  }

  Widget _buildFunctionList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: CupertinoIcons.person_circle_fill,
            label: "Thông tin cá nhân",
            subtitle: 'Xem và chỉnh sửa thông tin cá nhân',
            iconColor: const Color(0xFF4A90E2),
            onTap: () => Get.to(
                  () => const EditProfileScreen(),
              arguments: userViewModel.user.value,
            ),
          ),
          _buildDivider(),
          _buildListTile(
            icon: CupertinoIcons.map_fill,
            label: "Roadmap",
            subtitle: 'Lộ trình học phù hợp',
            iconColor: const Color(0xFF34C759),
            onTap: () {},
          ),
          _buildDivider(),
          _buildListTile(
            icon: CupertinoIcons.paperplane_fill,
            label: "Gửi đơn",
            subtitle: 'Gửi phản hồi và yêu cầu',
            iconColor: const Color(0xFFFF9500),
            onTap: () {},
          ),
          _buildDivider(),
          _buildListTile(
            icon: CupertinoIcons.cart_fill,
            label: "Đơn hàng của tôi",
            subtitle: 'Lịch sử đơn hàng & thanh toán',
            iconColor: const Color(0xFFFF3B30),
            onTap: () {},
          ),
          _buildDivider(),
          _buildListTile(
            icon: CupertinoIcons.arrow_right_square_fill,
            label: "Đăng xuất",
            subtitle: 'Thoát tài khoản hiện tại',
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
    String? subtitle,
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showArrow)
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 20,
                  color: Colors.grey.shade400,
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