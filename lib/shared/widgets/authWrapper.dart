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


    setupDI();
    final isLoggedIn = isAccessTokenValid();


    return isLoggedIn ? const NavigationMenu() : const LoginScreen();
  }
}