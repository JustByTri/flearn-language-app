import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
  final _fullnameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  final _formKey = GlobalKey<FormState>();

  // field-level error messages
  String? _emailError;
  String? _usernameError;

  @override
  void dispose() {
    _emailOrUserCtrl.dispose();
    _usernameCtrl.dispose();
    _fullnameCtrl.dispose();
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
        color: Colors.blue, // AppColors.primary
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final registerViewModel = Get.put(RegisterViewModel(Get.find()));

    InputDecoration fieldDecoration({required String hint, Widget? prefix, Widget? suffix}) {
      return InputDecoration(
        hintText: hint,
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(size),
              // XÓA header/logo màu tím tím (primary) bên dưới, chỉ giữ wave header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text('Đăng ký', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Username - no spaces allowed
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: fieldDecoration(hint: 'Tên người dùng (không dấu cách)', prefix: const Icon(Icons.person)).copyWith(errorText: _usernameError),
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        onChanged: (_) {
                          if (_usernameError != null) setState(() => _usernameError = null);
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập tên người dùng';
                          if (v.contains(' ')) return 'Tên người dùng không được chứa khoảng trắng';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email - must be a valid gmail address
                      TextFormField(
                        controller: _emailOrUserCtrl,
                        decoration: fieldDecoration(hint: 'Email (chỉ gmail)', prefix: const Icon(Icons.email)).copyWith(errorText: _emailError),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) {
                          if (_emailError != null) setState(() => _emailError = null);
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com\b');
                          if (!emailRegex.hasMatch(v)) return 'Email phải là gmail và đúng định dạng';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),




                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: fieldDecoration(
                          hint: 'Mật khẩu',
                          prefix: const Icon(Icons.lock),
                          suffix: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        obscureText: _obscure,
                        validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu >= 6 ký tự' : null,
                      ),
                      const SizedBox(height: 12),

                      // Confirm
                      TextFormField(
                        controller: _confirmCtrl,
                        decoration: fieldDecoration(
                          hint: 'Xác nhận mật khẩu',
                          prefix: const Icon(Icons.lock_outline),
                          suffix: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        obscureText: _obscureConfirm,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                          if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        child: Obx(() {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue, // Đổi thành màu xanh
                              foregroundColor: Colors.white, // Chữ trắng
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: registerViewModel.isLoading.value
                                ? null
                                : () async {
                                    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                                      // reset field errors
                                      setState(() {
                                        _emailError = null;
                                        _usernameError = null;
                                      });

                                      // Gọi register với đúng thứ tự: userName, email, password, confirmPassword
                                      final result = await registerViewModel.register(
                                        _usernameCtrl.text.trim(), // userName
                                        _emailOrUserCtrl.text.trim(), // email
                                        _passwordCtrl.text, // password
                                        _confirmCtrl.text, // confirmPassword
                                      );

                                      debugPrint('Register result: $result');

                                      if (!mounted) return;

                                      if (result['success'] == true) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(result['message'] ?? 'Đăng ký thành công.')),
                                        );
                                        debugPrint('Navigating to OTP screen with email: ${_emailOrUserCtrl.text.trim()}');
                                        // Use offAll to ensure navigation occurs and clears previous stack
                                        Get.offAll(() => OtpVerificationScreen(email: _emailOrUserCtrl.text.trim()));
                                        debugPrint('Navigation command executed');
                                      } else {
                                        final msg = (result['message'] ?? 'Đăng ký thất bại.').toString();
                                        debugPrint('Register failed with message: $msg');
                                        // assign to field-level error if message mentions email or username
                                        final lower = msg.toLowerCase();
                                        if (lower.contains('email')) {
                                          setState(() => _emailError = msg);
                                        } else if (lower.contains('tên người dùng') || lower.contains('username') || lower.contains('user name') || lower.contains('username')) {
                                          setState(() => _usernameError = msg);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(msg)),
                                          );
                                        }
                                      }
                                    }
                                  },
                            child: registerViewModel.isLoading.value
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Đăng ký', style: TextStyle(fontSize: 16, color: Colors.white)),
                          );
                        }),
                      ),
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
