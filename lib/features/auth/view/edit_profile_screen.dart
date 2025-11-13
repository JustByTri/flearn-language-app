import 'dart:io';
import 'package:flearn_app/features/auth/model/user.dart';
import 'package:flearn_app/features/auth/view/change_password_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../viewmodel/user_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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
    // Try to get user from arguments first
    _localUser = Get.arguments as User?;
    if (_localUser != null) {
      _initControllers(_localUser!);
    } else if (userViewModel.user.value != null) {
      _localUser = userViewModel.user.value;
      _initControllers(_localUser!);
    } else {
      _fetchUserIfNeeded();
    }

    // Keep local copy in sync with ViewModel
    ever(userViewModel.user, (user) {
      if (user != null) {
        setState(() {
          _localUser = user;
        });
        _initControllers(user);
      }
    });
  }

  void _initControllers(User user) {
    // Initialize lazily
    _fullNameController ??= TextEditingController(text: user.fullname ?? '');
    _userNameController ??= TextEditingController(text: user.username ?? '');

    // Attach listeners once to validate username in realtime
    if (!_listenersAttached) {
      _userNameController?.addListener(() {
        final err = _validateUsername(_userNameController?.text ?? '');
        if (err != _usernameError) {
          setState(() {
            _usernameError = err;
          });
        }
      });
      // full name listener to ensure not empty (allows Vietnamese)
      _fullNameController?.addListener(() {
        final isEmpty = (_fullNameController?.text ?? '').trim().isEmpty;
        if (isEmpty != _fullNameError) {
          setState(() {
            _fullNameError = isEmpty;
          });
        }
      });
      _listenersAttached = true;
    }

    // Always update text to latest
    _fullNameController?.text = user.fullname ?? '';
    _userNameController?.text = user.username ?? '';
  }

  String? _validateUsername(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Tên người dùng không được để trống';
    if (RegExp(r'\s').hasMatch(value)) return 'Tên không được chứa khoảng trắng';
    if (v.length < 3) return 'Tên phải có ít nhất 3 ký tự';
    // you can add more checks (allowed characters) here
    return null;
  }

  void _fetchUserIfNeeded() {
    if (!_fetchingUser) {
      _fetchingUser = true;
      userViewModel.fetchUserInfo().then((_) {
        _fetchingUser = false;
      });
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
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // Validate before submit
    final usernameVal = _userNameController?.text ?? '';
    final usernameErr = _validateUsername(usernameVal);
    if (usernameErr != null) {
      setState(() => _usernameError = usernameErr);
      Get.snackbar('Lỗi', usernameErr, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final success = await userViewModel.updateProfile(
      _fullNameController?.text ?? '',
      usernameVal,
      _avatarImage,
    );

    if (success) {
      Get.back();
      Get.snackbar('Thành công', 'Hồ sơ đã được cập nhật.', snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Lỗi', userViewModel.errorMessage.value ?? 'Không thể cập nhật hồ sơ.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _goToChangePassword() {
    Get.to(() => const ChangePasswordScreen());
  }

  bool _isFormValid() {
    final username = _userNameController?.text ?? '';
    final full = _fullNameController?.text ?? '';
    final usernameErr = _validateUsername(username);
    if (usernameErr != null) return false;
    if (full.trim().isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF1A1A1A)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Builder(builder: (context) {
        final user = _localUser;
        // If user is not yet loaded, show loading
        if (user == null) {
          return const Center(child: CupertinoActivityIndicator());
        }

        // Lazily initialize controllers if they are null when user becomes available
        _fullNameController ??= TextEditingController(text: user.fullname ?? '');
        _userNameController ??= TextEditingController(text: user.username ?? '');

        return SingleChildScrollView(
          child: Column(
            children: [
              // Header with avatar
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(25),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    _buildAvatar(user.avatar),
                    const SizedBox(height: 16),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (user.roles != null && user.roles!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.roles!.join(', '),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Form fields
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin tài khoản',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Username field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tên người dùng',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _userNameController,
                          decoration: InputDecoration(
                            hintText: 'Nhập tên người dùng',
                            errorText: _usernameError,
                            prefixIcon: const Icon(
                              CupertinoIcons.person,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s'))
                          ],
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.none,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Full name field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Họ và tên',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            hintText: 'Nhập họ và tên',
                            prefixIcon: const Icon(
                              CupertinoIcons.person_fill,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    StreamBuilder<bool>(
                      stream: userViewModel.isLoading.stream,
                      initialData: userViewModel.isLoading.value,
                      builder: (context, snapshot) {
                        final loading = snapshot.data ?? false;
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            onPressed: (loading || !_isFormValid())
                                ? null
                                : _submit,
                            child: loading
                                ? const CupertinoActivityIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Lưu thay đổi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Change password button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          side: const BorderSide(color: Colors.teal, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(CupertinoIcons.lock_shield),
                        label: const Text(
                          'Đổi mật khẩu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _goToChangePassword,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAvatar(String? currentAvatarUrl) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withAlpha(51),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: _avatarImage != null
                ? FileImage(_avatarImage!)
                : (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty
                    ? NetworkImage(currentAvatarUrl)
                    : null) as ImageProvider?,
            child: (_avatarImage == null &&
                    (currentAvatarUrl == null || currentAvatarUrl.isEmpty))
                ? Icon(
                    CupertinoIcons.person_fill,
                    size: 50,
                    color: Colors.grey.shade400,
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
