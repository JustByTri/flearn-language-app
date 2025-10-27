import 'dart:io';
import 'package:flearn_app/features/auth/model/user.dart';
import 'package:flearn_app/features/auth/view/change_password_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
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
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
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

        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        final viewPadding = MediaQuery.of(context).padding.bottom;
        final bottomPad = math.max(viewInsets, viewPadding) + 24.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, bottomPad),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAvatar(user.avatar),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.person, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.mail, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Text(user.email, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      if (user.roles != null && user.roles!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Chip(
                            label: Text(user.roles!.join(', ')),
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Username field: block whitespace and show validation
              _buildTextField(
                _userNameController!,
                'Tên người dùng',
                errorText: _usernameError,
                inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 20),
              // Full name: allow Vietnamese characters, capitalize words
              _buildTextField(
                _fullNameController!,
                'Họ và tên',
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              _buildSaveButton(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(CupertinoIcons.lock_shield),
                  label: const Text('Đổi mật khẩu'),
                  onPressed: _goToChangePassword,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAvatar(String? currentAvatarUrl) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _avatarImage != null
                ? FileImage(_avatarImage!)
                : (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty
                    ? NetworkImage(currentAvatarUrl)
                    : null) as ImageProvider?,
            child: (_avatarImage == null && (currentAvatarUrl == null || currentAvatarUrl.isEmpty))
                ? const Icon(CupertinoIcons.person_fill, size: 60, color: Colors.grey)
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
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? errorText, List<TextInputFormatter>? inputFormatters, TextInputType? keyboardType, TextCapitalization? textCapitalization}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
    );
  }

  Widget _buildSaveButton() {
    return StreamBuilder<bool>(
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: (loading || !_isFormValid()) ? null : _submit,
            child: loading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
