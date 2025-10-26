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
  final userViewModel = Get.put(UserViewModel(Get.find()));
  final loginViewModel = Get.find<LoginViewModel>();

  @override
  void initState() {
    super.initState();
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
      backgroundColor: Colors.white, // Nền trắng
      body: RefreshIndicator(
        onRefresh: _fetchUserProfile,
        child: Stack(
          children: [
            // Phần content chính
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 200), // Khoảng trống cho header và avatar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildFunctionList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Header và Avatar chồng lên
            _buildHeaderAndAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndAvatar() {
    return Obx(() {
      final user = userViewModel.user.value;
      final avatarUrl = user?.avatar;
      final username = user?.username ?? "Đang tải...";
      final email = user?.email ?? "Chào mừng đến với F-Learn";

      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Blue Header
          Container(
            height: 160,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 20), // Tạo khoảng trống cho avatar
                ],
              ),
            ),
          ),
          // Top icons
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.bell, color: Colors.white),
                  onPressed: () {
                    // Action for notification icon
                  },
                ),
              ],
            ),
          ),
          // Avatar
          Positioned(
            top: 110, // 160 (header height) - 50 (half of avatar height)
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? const Icon(CupertinoIcons.person_fill, color: Colors.grey, size: 50)
                    : null,
              ),
            ),
          ),
        ],
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
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          _buildListTile(
            icon: CupertinoIcons.person_circle,
            label: "Thông tin cá nhân",
            iconColor: Colors.blue,
            onTap: () {},
          ),
          const Divider(height: 1, indent: 50),
          _buildListTile(
            icon: CupertinoIcons.map,
            label: "Roadmap",
            iconColor: Colors.green,
            onTap: () {},
          ),
          const Divider(height: 1, indent: 50),
          _buildListTile(
            icon: CupertinoIcons.paperplane,
            label: "Gửi đơn",
            iconColor: Colors.orange,
            onTap: () {},
          ),
          
           const Divider(height: 1, indent: 50),
          _buildListTile(
            icon: CupertinoIcons.cart,
            label: "Đơn hàng của tôi",
            iconColor: Colors.redAccent,
            onTap: () {},
          ),
          const Divider(height: 1, indent: 50),
          _buildListTile(
            icon: Icons.logout,
            label: "Đăng xuất",
            iconColor: Colors.red,
            onTap: _showLogoutConfirmation,
            showArrow: false,
          ),
        ],
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
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: showArrow
          ? const Icon(CupertinoIcons.chevron_forward, size: 20, color: Colors.grey)
          : null,
    );
  }
}
