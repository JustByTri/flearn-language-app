// lib/features/auth/view/change_password_screen.dart

import 'package:dio/dio.dart';
import 'package:flearn_app/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import 'login_screen.dart';


class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final authService = Get.find<IAuthRepository>();

  bool get _isFormValid {
    return _oldPasswordCtrl.text.isNotEmpty &&
        _newPasswordCtrl.text.length >= 8 &&
        _newPasswordCtrl.text == _confirmPasswordCtrl.text;
  }

  @override
  void initState() {
    super.initState();
    _oldPasswordCtrl.addListener(() => setState(() {}));
    _newPasswordCtrl.addListener(() => setState(() {}));
    _confirmPasswordCtrl.addListener(() => setState(() {}));
  }

  Future<void> _submit() async {
    if (!_isFormValid || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final responseModel = await authService.changePassword(
        currentPassword: _oldPasswordCtrl.text.trim(),
        newPassword: _newPasswordCtrl.text.trim(),
        confirmPassword: _confirmPasswordCtrl.text.trim(),
      );

      // Normalize message and success from ResponseModel
      bool success = responseModel.isSuccess == true;
      String msg = responseModel.message ?? 'Đã có lỗi xảy ra!';

      // If the responseModel.result contains a map with more details use it
      try {
        if (responseModel.result != null && responseModel.result is Map<String, dynamic>) {
          final map = responseModel.result as Map<String, dynamic>;
          // backend might also return success/message inside data/result
          if (map.containsKey('success')) success = map['success'] == true;
          msg = map['message']?.toString() ?? map['error']?.toString() ?? msg;
          print('[ChangePassword] result payload map: $map');
        }
      } catch (e) {
        // ignore parsing errors and fallback to responseModel.message
        print('[ChangePassword] parsing result payload failed: $e');
      }

      print('[ChangePassword] normalized success=$success, msg=$msg');

      if (success) {
        await GetStorage().erase();
        print('[ChangePassword] success path - showing dialog');
        try { Get.closeAllSnackbars(); } catch (_) {}
        // Show modal dialog so message is always visible
        await Get.dialog(AlertDialog(
          title: const Text('Thành công'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text('OK'),
            ),
          ],
        ), barrierDismissible: false);
        // After dialog dismissed, navigate to login
        // Navigate to LoginScreen widget directly because no named '/login' route is defined
        Get.offAll(() => const LoginScreen());
      } else {
        print('[ChangePassword] error path - showing dialog with msg: $msg');
        try { Get.closeAllSnackbars(); } catch (_) {}
        await Get.dialog(AlertDialog(
          title: const Text('Lỗi'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ), barrierDismissible: true);
      }
    } on DioException catch (e) {
      // Log exception details for debugging
      print('[ChangePassword] DioException: ${e.message}');
      print('[ChangePassword] DioException response: ${e.response?.data}');

      String msg = 'Đã có lỗi xảy ra, vui lòng thử lại!';
      if (e.response?.data != null) {
        if (e.response!.data is Map<String, dynamic>) {
          final data = e.response!.data as Map<String, dynamic>;
          if (data.containsKey('message') && data['message'] != null && data['message'].toString().isNotEmpty) {
            msg = data['message'];
          } else if (data.containsKey('error') && data['error'] != null && data['error'].toString().isNotEmpty) {
            msg = data['error'];
          }
        } else if (e.response!.data is String && e.response!.data.toString().isNotEmpty) {
          msg = e.response!.data.toString();
        }
      }
      print('[ChangePassword] showing error dialog from DioException: $msg');
      try { Get.closeAllSnackbars(); } catch (_) {}
      await Get.dialog(AlertDialog(
        title: const Text('Lỗi'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ), barrierDismissible: true);

    } catch (e) {
      print('[ChangePassword] unexpected error: $e');
      await Get.dialog(AlertDialog(
        title: const Text('Lỗi'),
        content: const Text('Đã có lỗi xảy ra!'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ), barrierDismissible: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Đổi mật khẩu',
          style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isFormValid && !_isLoading ? _submit : null,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey))
                : Text(
              'Lưu',
              style: GoogleFonts.quicksand(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _isFormValid ? AppColors.primary : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tạo mật khẩu mới',
              style: GoogleFonts.quicksand(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Mật khẩu mới phải khác với mật khẩu đã sử dụng trước đó.',
              style: GoogleFonts.quicksand(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 48),

            _buildPasswordField(
              controller: _oldPasswordCtrl,
              label: 'Mật khẩu hiện tại',
              obscure: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
            ),
            const SizedBox(height: 32),

            _buildPasswordField(
              controller: _newPasswordCtrl,
              label: 'Mật khẩu mới',
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              helperText: 'Tối thiểu 8 ký tự',
            ),
            const SizedBox(height: 32),

            _buildPasswordField(
              controller: _confirmPasswordCtrl,
              label: 'Xác nhận mật khẩu',
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              helperText: _newPasswordCtrl.text.isNotEmpty && _newPasswordCtrl.text != _confirmPasswordCtrl.text
                  ? 'Mật khẩu không khớp'
                  : null,
              hasError: _newPasswordCtrl.text.isNotEmpty && _newPasswordCtrl.text != _confirmPasswordCtrl.text,
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? helperText,
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.quicksand(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: 'Nhập $label',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.lock_outline, color: hasError ? Colors.red : Colors.grey.shade600, size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade600),
              onPressed: onToggle,
            ),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: hasError ? Colors.red : AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(helperText, style: GoogleFonts.quicksand(fontSize: 13, color: hasError ? Colors.red : Colors.grey.shade500)),
        ],
      ],
    );
  }
}