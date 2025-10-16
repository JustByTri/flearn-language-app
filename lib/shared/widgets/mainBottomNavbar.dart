import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../core/constants/colors.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: GNav(
            gap: 6,
            activeColor: AppColors.primary,
            iconSize: 22,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabBackgroundColor: AppColors.primary.withOpacity(0.1),
            color: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            tabMargin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            tabBorderRadius: 12,
            curve: Curves.easeInOutCubic,
            duration: const Duration(milliseconds: 300),
            selectedIndex: currentIndex,
            onTabChange: onTap,
            tabs: const [
              GButton(
                icon: Icons.home_rounded,
                text: 'Trang chủ',
              ),
              GButton(
                icon: Icons.chat_rounded,
                text: 'AI Chat',
              ),
              GButton(
                icon: Icons.menu_book_rounded,
                text: 'Khóa học',
              ),
              GButton(
                icon: Icons.person_rounded,
                text: 'Tài khoản',
              ),
            ],
          ),
        ),
      ),
    );
  }
}