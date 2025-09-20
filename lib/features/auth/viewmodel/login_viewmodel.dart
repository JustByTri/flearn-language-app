import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/auth_repository.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';

class LoginViewModel extends GetxController {
  final IAuthRepository _authRepository;
  final storage = GetStorage();
  var isLoading = false.obs;

  LoginViewModel(this._authRepository);

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      print(" Starting login with email: $email");

      final request = LoginRequest(usernameOrEmail: email, password: password);
      final response = await _authRepository.login(request);

      print("Login response - isSuccess: ${response.isSuccess}");
      print(" Login response - result: ${response.result}");

      if (response.isSuccess && response.result != null) {
        await storage.write('accessToken', response.result!.accessToken);
        await storage.write('refreshToken', response.result!.refreshToken);
        print(" Login successful - tokens saved");
        return true;
      } else {
        print(" Login failed - isSuccess: ${response.isSuccess}, result is null: ${response.result == null}");
        return false;
      }

    } catch (e) {
      print(" Login exception: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
