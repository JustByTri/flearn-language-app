import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../features/auth/view/home_screen.dart';
import '../../features/auth/view/profile_screen.dart';
import '../../features/course/view/course_screen.dart';
import '../../features/topic/view/topic_screen.dart';

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  Widget getScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const TopicScreen();
      case 2:
        return const CourseScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  void onDestinationSelected(int index) {
    selectedIndex.value = index;
  }
}

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController controller = Get.put(NavigationController());

    return Scaffold(
      body: Obx(
            () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: SizedBox(
            key: ValueKey<int>(controller.selectedIndex.value),
            child: controller.getScreen(controller.selectedIndex.value),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Obx(() {
            final currentIndex = controller.selectedIndex.value;
            return SizedBox(
              height: 65,
              child: Stack(
                children: [
                  // Animated sliding indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    left: currentIndex * (MediaQuery.of(context).size.width / 4),
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width / 4,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Nav items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_rounded,
                        label: 'Trang chủ',
                        index: 0,
                        currentIndex: currentIndex,
                        onTap: () => controller.onDestinationSelected(0),
                      ),
                      _buildNavItem(
                        icon: Icons.chat_bubble_rounded,
                        label: 'AI Chat',
                        index: 1,
                        currentIndex: currentIndex,
                        onTap: () => controller.onDestinationSelected(1),
                      ),
                      _buildNavItem(
                        icon: Icons.menu_book_rounded,
                        label: 'Khóa học',
                        index: 2,
                        currentIndex: currentIndex,
                        onTap: () => controller.onDestinationSelected(2),
                      ),
                      _buildNavItem(
                        icon: Icons.person_rounded,
                        label: 'Tài khoản',
                        index: 3,
                        currentIndex: currentIndex,
                        onTap: () => controller.onDestinationSelected(3),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}