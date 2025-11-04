import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../viewmodel/forgotPassword_viewmodel.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({required this.email, super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final ForgotPasswordViewModel forgotPasswordVM = Get.find<ForgotPasswordViewModel>();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await forgotPasswordVM.resetPassword(
      widget.email,
      otpController.text.trim(),
      newPasswordController.text.trim(),
      confirmPasswordController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } else {
      String errorMsg = 'Đổi mật khẩu thất bại!';
      if (result['error'] != null) {
        errorMsg = result['error'];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // === WAVE HEADER GIỐNG LOGIN ===
                ClipPath(
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
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.school, size: 60, color: Colors.white);
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),

                // === FORM CONTENT ===
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Đặt lại mật khẩu',
                          style: TextStyle(
                            fontSize: (size.width * 0.08).clamp(28.0, 34.0),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nhập mã OTP và mật khẩu mới cho',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.email,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Mã OTP',
                            prefixIcon: const Icon(Icons.email_outlined),
                            counterText: '',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mã OTP';
                            if (v.trim().length != 6) return 'Mã OTP phải có đúng 6 số';
                            if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) return 'Mã OTP chỉ chứa số';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: newPasswordController,
                          obscureText: _obscureNew,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu mới',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureNew = !_obscureNew),
                            ),
                            helperText: 'Ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt',
                            helperMaxLines: 2,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mật khẩu mới';
                            if (v.trim().length < 8) return 'Mật khẩu cần ít nhất 8 ký tự';
                            if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$').hasMatch(v.trim())) {
                              return 'Mật khẩu phải có chữ hoa, chữ thường, số và ký tự đặc biệt';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Xác nhận mật khẩu',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Vui lòng xác nhận mật khẩu';
                            if (v.trim() != newPasswordController.text.trim()) return 'Mật khẩu không khớp';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: forgotPasswordVM.isLoading.value ? null : _onSubmit,
                            child: forgotPasswordVM.isLoading.value
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Đổi mật khẩu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        )),

                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                            );
                          },
                          child: Text('Quay lại đăng nhập', style: TextStyle(color: AppColors.primary)),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Obx(() => forgotPasswordVM.isLoading.value
              ? Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text("Đang xử lý...", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}

// === WAVE CLIPPER GIỐNG LOGIN ===
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.85);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.2, size.height - 30);
    path.quadraticBezierTo(
        firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 3.2), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
        secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}