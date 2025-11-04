import 'package:flearn_app/di.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/auth/view/login_screen.dart';
import '../../shared/widgets/mainBottomNavbar.dart'; // NavigationMenu
import '../../utils/decode_token.dart'; // Import hàm kiểm tra token

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Kiểm tra token hợp lệ

    setupDI();
    final isLoggedIn = isAccessTokenValid();

    // Nếu token hợp lệ, chuyển đến NavigationMenu; nếu không, đến LoginScreen
    return isLoggedIn ? const NavigationMenu() : const LoginScreen();
  }
}