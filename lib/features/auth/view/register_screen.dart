import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../../shared/widgets/my_textfield.dart';
import '../viewmodel/register_viewmodel.dart';
import 'otpverification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final registerViewModel = Get.put(RegisterViewModel(Get.find()));

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (nameController.text.trim().isEmpty) {
      _showSnackBar("Vui lòng nhập tên", Colors.orange);
      return;
    }

    if (emailController.text.trim().isEmpty) {
      _showSnackBar("Vui lòng nhập email", Colors.orange);
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      _showSnackBar("Vui lòng nhập mật khẩu", Colors.orange);
      return;
    }

    if (confirmPasswordController.text.trim() != passwordController.text.trim()) {
      _showSnackBar("Xác nhận mật khẩu không khớp", Colors.orange);
      return;
    }

    final success = await registerViewModel.register(
      nameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
      confirmPasswordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar("Đăng ký thành công!", Colors.green);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(email: emailController.text.trim()),
        ),
      );
    } else {
      _showSnackBar("Đăng ký thất bại", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.9),
              AppColors.primary.withOpacity(0.6),
              AppColors.primary.withOpacity(0.3),
              Colors.white,
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundCircles(width, height),
            _buildMainContent(width, height),
            _buildLoadingOverlay(width, height),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundCircles(double width, double height) {
    return Stack(
      children: [
        Positioned(
          top: -height * 0.05,
          right: -width * 0.1,
          child: Container(
            width: width * 0.3,
            height: width * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          bottom: -height * 0.03,
          left: -width * 0.08,
          child: Container(
            width: width * 0.25,
            height: width * 0.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(double width, double height) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(width, height),
                          SizedBox(height: height * 0.05),
                          MyTextField(
                            controller: nameController,
                            hintText: "Họ và tên",
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: height * 0.025),
                          MyTextField(
                            controller: emailController,
                            hintText: "Email",
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: height * 0.025),
                          MyTextField(
                            controller: passwordController,
                            hintText: "Password",
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.primary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: height * 0.025),
                          MyTextField(
                            controller: confirmPasswordController,
                            hintText: "Confirm Password",
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.primary,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleRegister(),
                          ),
                          SizedBox(height: height * 0.04),
                          _buildRegisterButton(width, height),
                          SizedBox(height: height * 0.04),
                          _buildSignInLink(width),
                          SizedBox(height: height * 0.025),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double width, double height) {
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            width: width * 0.2,
            height: width * 0.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(width * 0.1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
                Icons.person_add_rounded,
                size: width * 0.1,
                color: Colors.white
            ),
          ),
        ),
        SizedBox(height: height * 0.03),
        Text(
          "Tạo tài khoản mới",
          style: TextStyle(
            fontSize: width * 0.07,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: height * 0.01),
        Text(
          "Bắt đầu hành trình học tập của bạn",
          style: TextStyle(
            fontSize: width * 0.04,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(double width, double height) {
    return Obx(
          () => Container(
        width: double.infinity,
        height: height * 0.07,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: registerViewModel.isLoading.value ? null : _handleRegister,
          child: registerViewModel.isLoading.value
              ? SizedBox(
            width: width * 0.06,
            height: width * 0.06,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          )
              : Text(
            "Đăng ký",
            style: TextStyle(
              fontSize: width * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInLink(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Đã có tài khoản? ",
          style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: width * 0.038
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Đăng nhập",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.038,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(double width, double height) {
    return Obx(
          () => registerViewModel.isLoading.value
          ? Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(width * 0.08),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: height * 0.02),
                  Text(
                      "Đang đăng ký...",
                      style: TextStyle(fontSize: width * 0.04)
                  ),
                ],
              ),
            ),
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }
}