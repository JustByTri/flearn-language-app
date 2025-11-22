import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../viewmodel/register_viewmodel.dart';
import 'otpverification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailOrUserCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  final _formKey = GlobalKey<FormState>();

  String? _emailError;
  String? _usernameError;

  @override
  void dispose() {
    _emailOrUserCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
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
    );
  }

  InputDecoration fieldDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final registerViewModel = Get.put(RegisterViewModel(Get.find()));

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(size),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Đăng ký',
                        style: TextStyle(
                          fontSize: (size.width * 0.08).clamp(28.0, 34.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Username
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: fieldDecoration(
                          hint: 'Tên người dùng (không dấu cách)',
                          prefix: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                          errorText: _usernameError,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        onChanged: (_) {
                          if (_usernameError != null) {
                            setState(() => _usernameError = null);
                          }
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập tên người dùng';
                          if (v.contains(' ')) return 'Không được chứa khoảng trắng';
                          if (v.length < 3) return 'Tối thiểu 3 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Email
                      TextFormField(
                        controller: _emailOrUserCtrl,
                        decoration: fieldDecoration(
                          hint: 'Email (chỉ gmail)',
                          prefix: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                          errorText: _emailError,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                        // validator: (v) {
                        //   if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                        //   final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
                        //   if (!emailRegex.hasMatch(v)) return 'Email phải là @gmail.com';
                        //   return null;
                        // },
                      ),
                      const SizedBox(height: 20),

                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: fieldDecoration(
                          hint: 'Mật khẩu',
                          prefix: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                          suffix: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                          if (v.length < 6) return 'Mật khẩu >= 6 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        decoration: fieldDecoration(
                          hint: 'Xác nhận mật khẩu',
                          prefix: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                          suffix: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                          if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng ký
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Obx(() {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: registerViewModel.isLoading.value
                                ? null
                                : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _emailError = null;
                                  _usernameError = null;
                                });

                                final result = await registerViewModel.register(
                                  _usernameCtrl.text.trim(),
                                  _emailOrUserCtrl.text.trim(),
                                  _passwordCtrl.text,
                                  _confirmCtrl.text,
                                );

                                if (!mounted) return;

                                if (result['success'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message'] ?? 'Đăng ký thành công!'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  Get.offAll(() => OtpVerificationScreen(
                                    email: _emailOrUserCtrl.text.trim(),
                                  ));
                                } else {
                                  final msg = result['message']?.toString() ?? 'Đăng ký thất bại.';
                                  final lower = msg.toLowerCase();

                                  if (lower.contains('email')) {
                                    setState(() => _emailError = msg);
                                  } else if (lower.contains('tên người dùng') ||
                                      lower.contains('username')) {
                                    setState(() => _usernameError = msg);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            child: registerViewModel.isLoading.value
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              'Đăng ký',
                              style: TextStyle(
                                fontSize: (size.width * 0.045).clamp(16.0, 18.0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      // Đăng nhập?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Đã có tài khoản? ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: (size.width * 0.038).clamp(13.0, 15.0),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text(
                              'Đăng nhập',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: (size.width * 0.038).clamp(13.0, 15.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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