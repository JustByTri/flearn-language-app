import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/auth_repository.dart';
import '../model/login_request.dart';

class LoginViewModel extends GetxController {
  final IAuthRepository _authRepository;
  final storage = GetStorage();
  var isLoading = false.obs;

  LoginViewModel(this._authRepository);

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      print(" Starting login with email: $email");

      final request = LoginRequest(
        usernameOrEmail: email,
        password: password,
      );
      final response = await _authRepository.login(request);

      print(
        "Login response - isSuccess: ${response.isSuccess}",
      );
      print(" Login response - result: ${response.result}");

      if (response.isSuccess && response.result != null) {
        await storage.write(
          'accessToken',
          response.result!.accessToken,
        );
        await storage.write(
          'refreshToken',
          response.result!.refreshToken,
        );

        print(" Login successful - tokens saved");
        return true;
      } else {
        print(
          " Login failed - isSuccess: ${response.isSuccess}, result is null: ${response.result == null}",
        );
        return false;
      }
    } catch (e) {
      print(" Login exception: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      isLoading.value = true;
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: dotenv.env['GOOGLE_CLIENT_ID'],
      );
      final account = await googleSignIn.signIn();
      final auth = await account?.authentication;
      if (auth?.idToken == null) {
        throw Exception("No Google ID Token found");
      }
      debugPrint('Google ID Token: ${auth!.idToken}');
      final response = await _authRepository
          .loginWithGoogle(auth.idToken!);
      if (response.isSuccess && response.result != null) {

        await storage.write('accessToken', response.result!.accessToken);
        await storage.write('refreshToken', response.result!.refreshToken);
        debugPrint("Login thành công, data from api: ${response.result}");
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Sign-in error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  String? getAccessToken() {
    return storage.read('accessToken');
  }

  String? getRefreshToken() {
    return storage.read('refreshToken');
  }

  void logout() {
    storage.remove('accessToken');
    storage.remove('refreshToken');
  }

  Future<Map<String, dynamic>?>
  checkSurveyRequired() async {
    try {
      final result = await _authRepository
          .checkSurveyRequired();
      return result;
    } catch (e) {
      print("checkSurveyRequired error: $e");
      return null;
    }
  }
}
