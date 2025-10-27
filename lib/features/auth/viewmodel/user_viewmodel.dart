import 'dart:io';

import 'package:flearn_app/features/auth/model/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../data/auth_repository.dart';

class UserViewModel extends GetxController {
  final IAuthRepository _authRepository;
  UserViewModel(this._authRepository);
  var user = Rxn<User>();
  var isLoading = false.obs;
  var errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      isLoading.value = true;
      final response = await _authRepository.fetchProfile();
      // Debug logs
      debugPrint('fetchUserInfo - response.isSuccess: ${response.isSuccess}, statusCode: ${response.statusCode}, message: ${response.message}');
      debugPrint('fetchUserInfo - response.result: ${response.result}');
      if(response.isSuccess == true && response.result != null) {
        user.value = response.result;
      } else {
        errorMessage.value = response.message ?? 'Failed to fetch user info';
      }
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint('fetchUserInfo error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile(String fullName, String userName, File? avatar) async {
    try {
      isLoading.value = true;
      final response = await _authRepository.updateProfile(
        fullName: fullName,
        userName: userName,
        avatar: avatar,
      );
      if (response.isSuccess == true) {
        await fetchUserInfo(); // Refresh user info
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to update profile';
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      isLoading.value = true;
      final response = await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      if (response.isSuccess == true) {
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to change password';
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
