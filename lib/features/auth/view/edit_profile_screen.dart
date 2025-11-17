// lib/features/auth/view/edit_profile_screen.dart

import 'dart:io';
import 'package:flearn_app/features/auth/model/user.dart';
import 'package:flearn_app/features/auth/view/change_password_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../viewmodel/user_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final userViewModel = Get.find<UserViewModel>();
  User? _localUser;
  TextEditingController? _fullNameController;
  TextEditingController? _userNameController;
  final ImagePicker _picker = ImagePicker();
  File? _avatarImage;
  bool _fetchingUser = false;
  bool _listenersAttached = false;
  String? _usernameError;
  bool _fullNameError = false;

  @override
  void initState() {
    super.initState();

    _localUser = Get.arguments as User?;
    if (_localUser != null) {
      _initControllers(_localUser!);
    } else if (userViewModel.user.value != null) {
      _localUser = userViewModel.user.value;
      _initControllers(_localUser!);
    } else {
      _fetchUserIfNeeded();
    }

    ever(userViewModel.user, (user) {
      if (user != null && mounted) {
        setState(() => _localUser = user);
        _initControllers(user);
      }
    });
  }

  void _initControllers(User user) {
    _fullNameController ??= TextEditingController(text: user.fullname ?? '');
    _userNameController ??= TextEditingController(text: user.username ?? '');

    if (!_listenersAttached) {
      _userNameController?.addListener(() {
        final err = _validateUsername(_userNameController?.text ?? '');
        if (err != _usernameError) {
          setState(() => _usernameError = err);
        }
      });
      _fullNameController?.addListener(() {
        final isEmpty = (_fullNameController?.text ?? '').trim().isEmpty;
        if (isEmpty != _fullNameError) {
          setState(() => _fullNameError = isEmpty);
        }
      });
      _listenersAttached = true;
    }

    _fullNameController?.text = user.fullname ?? '';
    _userNameController?.text = user.username ?? '';
  }

  String? _validateUsername(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Tên người dùng không được để trống';
    if (RegExp(r'\s').hasMatch(value)) return 'Tên không được chứa khoảng trắng';
    if (v.length < 3) return 'Tên phải có ít nhất 3 ký tự';
    return null;
  }

  void _fetchUserIfNeeded() {
    if (!_fetchingUser) {
      _fetchingUser = true;
      userViewModel.fetchUserInfo().then((_) => _fetchingUser = false);
    }
  }

  @override
  void dispose() {
    _fullNameController?.dispose();
    _userNameController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _avatarImage = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final usernameErr = _validateUsername(_userNameController?.text ?? '');
    if (usernameErr != null) {
      setState(() => _usernameError = usernameErr);
      Get.snackbar('Lỗi', usernameErr, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final success = await userViewModel.updateProfile(
      _fullNameController?.text ?? '',
      _userNameController?.text ?? '',
      _avatarImage,
    );

    if (success) {
      Get.back();
      Get.snackbar('Thành công', 'Hồ sơ đã được cập nhật.', backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('Lỗi', userViewModel.errorMessage.value ?? 'Cập nhật thất bại', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _goToChangePassword() => Get.to(() => const ChangePasswordScreen());

  bool _isFormValid() {
    final username = _userNameController?.text ?? '';
    final full = _fullNameController?.text ?? '';
    return _validateUsername(username) == null && full.trim().isNotEmpty;
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
          'Thông tin cá nhân',
          style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isFormValid() ? _submit : null,
            child: Text(
              'Lưu',
              style: GoogleFonts.quicksand(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _isFormValid() ? AppColors.primary : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: _localUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Avatar + Upload Photo
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _avatarImage != null
                        ? FileImage(_avatarImage!)
                        : (_localUser!.avatar != null && _localUser!.avatar!.isNotEmpty
                        ? NetworkImage(_localUser!.avatar!)
                        : null),
                    child: _avatarImage == null && (_localUser!.avatar == null || _localUser!.avatar!.isEmpty)
                        ? Icon(CupertinoIcons.person, size: 60, color: Colors.grey.shade400)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thay đổi avatar',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),

            // Name
            _buildInfoRow('Họ và Tên', _fullNameController!, CupertinoIcons.person_fill),
            const SizedBox(height: 24),

            // Username (nếu có)
            if (_userNameController != null)
              _buildInfoRow('Tên tài khoản', _userNameController!, CupertinoIcons.at, errorText: _usernameError),
            const SizedBox(height: 24),

            // Email - chỉ đọc
            _buildReadOnlyRow('Email', _localUser!.email, CupertinoIcons.mail, hasCheck: true),
            const SizedBox(height: 19),



            // Nút đổi mật khẩu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _goToChangePassword,
                icon: const Icon(CupertinoIcons.lock_shield, color: AppColors.primary),
                label: Text(
                  'Đổi mật khẩu',
                  style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, TextEditingController controller, IconData icon, {String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          inputFormatters: label == 'Username' ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))] : null,
          decoration: InputDecoration(
            errorText: errorText,
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
            border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyRow(String label, String? value, IconData icon, {bool hasCheck = false, bool hasDot = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? '-',
                style: GoogleFonts.quicksand(fontSize: 17, fontWeight: FontWeight.w500),
              ),
            ),
            if (hasCheck)
              const Icon(Icons.check_circle, color: Colors.green, size: 20)
            else if (hasDot)
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle))
            else if (label == 'Zip Code')
                const Icon(Icons.sync, color: Colors.grey),
          ],
        ),
        const Divider(height: 32),
      ],
    );
  }
}