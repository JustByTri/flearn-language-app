import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/my_textField.dart';
import '../../survey/view/survey_screen.dart';
import '../viewmodel/login_viewmodel.dart';
import 'forgotpassword_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final loginViewModel = Get.put(LoginViewModel(Get.find()));
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập email"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập mật khẩu"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await loginViewModel.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {

      final surveyStatus = await loginViewModel.checkSurveyRequired();
      if (surveyStatus != null) {
        final box = GetStorage();
        box.write('surveyStatus', surveyStatus);
      }

      if (surveyStatus == null) {

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
        return;
      }


      if (surveyStatus['assessmentRequired'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SurveyScreen()),
              (route) => false,
        );
      } else {

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(child: Text("Thông tin đăng nhập không chính xác")),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _onGoogleLoginPressed() async {
    try {
      loginViewModel.isLoading.value = true;
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (!mounted) return;

      if (googleUser == null) {
        _showErrorSnackBar("Đăng nhập Google bị hủy");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        _showSuccessSnackBar("Đăng nhập Google thành công!");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SurveyScreen()),
              (route) => false,
        );
      } else {
        _showErrorSnackBar("Đăng nhập Google thất bại");
      }
    } catch (e, stackTrace) {
      if (mounted) {
        _showErrorSnackBar("Lỗi đăng nhập Google: $e");
        debugPrint("Google Sign-In Error: $e\n$stackTrace");
      }
    } finally {
      if (mounted) {
        loginViewModel.isLoading.value = false;
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void _dismissKeyboard() => FocusScope.of(context).unfocus();
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.04;

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        body: Container(
          color: AppColors.primary.withOpacity(0.6),
          child: Stack(
            children: [
              _buildMainContent(context, padding),
              _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, double padding) {
    final size = MediaQuery.of(context).size;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(),
              SizedBox(height: size.height * 0.04),
              _buildEmailField(),
              SizedBox(height: size.height * 0.025),
              _buildPasswordField(),
              SizedBox(height: size.height * 0.02),
              _buildRememberMeAndForgotPassword(context),
              SizedBox(height: size.height * 0.04),
              _buildLoginButton(context),
              SizedBox(height: size.height * 0.03),
              _buildDivider(),
              SizedBox(height: size.height * 0.03),
              _buildGoogleLoginButton(context),
              SizedBox(height: size.height * 0.04),
              _buildSignUpLink(context),
              SizedBox(height: size.height * 0.025),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.18;

    return Hero(
      tag: 'app_logo',
      child: Container(
        width: logoSize,
        height: logoSize,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(logoSize / 2),
        ),
        child: Icon(
          Icons.school_rounded,
          size: logoSize * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return MyTextField(
      controller: emailController,
      hintText: "Email hoặc tên người dùng",
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    final size = MediaQuery.of(context).size;

    return MyTextField(
      controller: passwordController,
      hintText: "Mật khẩu",
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.primary,
          size: size.width * 0.05,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _onLoginPressed(),
    );
  }

  Widget _buildRememberMeAndForgotPassword(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size.width * 0.05,
                height: size.width * 0.05,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) => setState(() => _rememberMe = value ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              SizedBox(width: size.width * 0.01),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Text(
                    'Ghi nhớ đăng nhập',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: (size.width * 0.035).clamp(12.0, 14.0),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              },
              child: Text(
                "Quên mật khẩu?",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: (size.width * 0.035).clamp(12.0, 14.0),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: loginViewModel.isLoading.value ? null : _onLoginPressed,
        child: Text(
          "Đăng nhập",
          style: TextStyle(
            fontSize: (size.width * 0.045).clamp(14.0, 16.0),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final size = MediaQuery.of(context).size;

    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[400])),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
          child: Text(
            'Hoặc',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: (size.width * 0.035).clamp(12.0, 14.0),
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildGoogleLoginButton(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRect(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: loginViewModel.isLoading.value ? null : _onGoogleLoginPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              SvgPicture.asset(
                'assets/icons/google-icon-logo-svgrepo-com.svg',
                width: size.width * 0.04,
                height: size.width * 0.04,
              ),
              SizedBox(width: size.width * 0.01),
              Expanded(
                child: Text(
                  "Đăng nhập với Google",
                  style: TextStyle(
                    fontSize: (size.width * 0.035).clamp(12.0, 14.0),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Chưa có tài khoản? ",
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: (size.width * 0.035).clamp(12.0, 14.0),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: Text(
            "Đăng ký ngay",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: (size.width * 0.035).clamp(12.0, 14.0),
            ),
            overflow: TextOverflow.ellipsis,
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
            color: AppColors.primary,
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }
}