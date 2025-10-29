import 'package:flearn_app/features/auth/view/welcome_survey_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../../shared/widgets/mainBottomNavbar.dart';
import '../../../shared/widgets/my_textField.dart';
import '../viewmodel/login_viewmodel.dart';
import 'forgotpassword_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final loginViewModel = Get.put(
    LoginViewModel(Get.find()),
  );
  bool _obscurePassword = true;
  bool _rememberMe = false;

  

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (emailController.text.trim().isEmpty) {
      _showErrorSnackBar("Vui lòng nhập email của bạn");
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      _showErrorSnackBar("Vui lòng nhập mật khẩu");
      return;
    }

    final result = await loginViewModel.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccessSnackBar("Đăng nhập thành công!");
      if (result['surveyRequired'] == true) {
        Get.offAll(() => const WelcomeSurveyScreen());
      } else {
        Get.offAll(() => const NavigationMenu());
      }
    } else {
      _showErrorSnackBar("Thông tin đăng nhập không chính xác");
    }
  }

  Future<void> _onGoogleLoginPressed() async {
    try {
      final result = await loginViewModel.loginWithGoogle();

      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccessSnackBar("Đăng nhập Google thành công!");
        if (result['surveyRequired'] == true) {
          Get.offAll(() => const WelcomeSurveyScreen());
        } else {
          Get.offAll(() => const NavigationMenu());
        }
      } else {
        _showErrorSnackBar("Đăng nhập Google thất bại");
      }
    } catch (e) {
      debugPrint('Sign-in error: $e');
      _showErrorSnackBar("Đã có lỗi xảy ra. Vui lòng thử lại.");
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // --- Main Content ---
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(size),
                  _buildForm(size),
                ],
              ),
            ),

            // --- Loading Overlay ---
            _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: size.height * 0.30,
        width: double.infinity,
        color: AppColors.primary,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'app_logo',
                child: Transform.scale(
                  scale: 5.0,
                  child: Image.asset(
                    'assets/images/1.png',
                    width: (size.width * 0.25).clamp(100.0, 180.0),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // --- ĐĂNG NHẬP TITLE ---
          Text(
            "Đăng nhập",
            style: TextStyle(
              fontSize: (size.width * 0.08).clamp(28.0, 34.0),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildEmailField(),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 16),
          _buildRememberMeAndForgotPassword(),
          const SizedBox(height: 24),
          _buildLoginButton(),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildGoogleLoginButton(),
          const SizedBox(height: 24),
          _buildSignUpLink(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return MyTextField(
      controller: emailController,
      hintText: "Email hoặc tên người dùng",
      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return MyTextField(
      controller: passwordController,
      hintText: "Mật khẩu",
      obscureText: _obscurePassword,
      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _onLoginPressed(),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    final size = MediaQuery.of(context).size;
    final style = TextStyle(
      color: AppColors.textSecondary,
      fontSize: (size.width * 0.035).clamp(12.0, 14.0),
      fontWeight: FontWeight.w500,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) => setState(() => _rememberMe = value ?? false),
                activeColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
              Text('Ghi nhớ', style: style),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
          ),
          child: Text("Quên mật khẩu?", style: style.copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: loginViewModel.isLoading.value ? null : _onLoginPressed,
        child: Text(
          "Đăng nhập",
          style: TextStyle(
            fontSize: (size.width * 0.045).clamp(16.0, 18.0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Hoặc', style: TextStyle(color: Colors.grey[600])),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleLoginButton() {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: loginViewModel.isLoading.value ? null : _onGoogleLoginPressed,
        icon: SvgPicture.asset(
          'assets/icons/google-icon-logo-svgrepo-com.svg',
          width: size.width * 0.05,
        ),
        label: Text(
          "Đăng nhập với Google",
          style: TextStyle(
            fontSize: (size.width * 0.04).clamp(14.0, 16.0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    final size = MediaQuery.of(context).size;
    final style = TextStyle(
      color: AppColors.textSecondary,
      fontSize: (size.width * 0.038).clamp(13.0, 15.0),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Chưa có tài khoản?", style: style),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
          ),
          child: Text(
            "Đăng ký ngay",
            style: style.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Obx(
      () => loginViewModel.isLoading.value
          ? Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// Custom Clipper for the wave effect
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.85); // Start
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.2, size.height - 30.0);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
        Offset(size.width - (size.width / 3.2), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
