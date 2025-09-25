import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/auth_repository.dart';

class RegisterViewModel extends GetxController {
  final IAuthRepository _authRepository;
  final storage = GetStorage();
  var isLoading = false.obs;

  RegisterViewModel(this._authRepository);

  Future<bool> register(
      String userName,
      String email,
      String password,
      String confirmedPassword,
      ) async {
    try {
      isLoading.value = true;
      print("Starting registration with email: $email");

      final response = await _authRepository.register(
        userName,
        email,
        password,
        confirmedPassword,
      );

      print("Register response - isSuccess: ${response.isSuccess}");
      print("Register response - result: ${response.result}");

      if (response.isSuccess) {
        print("Registration successful - waiting for OTP verification");
        return true;
      } else {
        print("Registration failed - isSuccess: ${response.isSuccess}");
        return false;
      }

    } catch (e) {
      print(" Registration exception: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}