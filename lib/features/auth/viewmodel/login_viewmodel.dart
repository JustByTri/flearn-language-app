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
  void logout() {
    storage.remove('accessToken');
    storage.remove('refreshToken');
    storage.remove('user');
  }
  LoginViewModel(this._authRepository);

  Future<Map<String, bool>> login(String email, String password) async {
    try {
      isLoading.value = true;

      final request = LoginRequest(
        usernameOrEmail: email,
        password: password,
      );
      final response = await _authRepository.login(request);

      if (response.isSuccess && response.result != null) {
        await storage.write('accessToken', response.result!.accessToken,);
        await storage.write('refreshToken', response.result!.refreshToken,);

        await storage.write('user', {
          ...?response.result!.user,
          'languageId': response.result!.activeLanguage?['languageId'],
          'languageName': response.result!.activeLanguage?['languageName'],
          'languageCode': response.result!.activeLanguage?['languageCode'],
        });

        final surveyRequired = response.result!.activeLanguage == null;
        return {'success': true, 'surveyRequired': surveyRequired};
      } else {
        return {'success': false, 'surveyRequired': false};
      }
    } catch (e) {
      debugPrint("Login exception: $e");
      return {'success': false, 'surveyRequired': false};
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, bool>> loginWithGoogle() async {
    try {
      isLoading.value = true;
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: dotenv.env['GOOGLE_CLIENT_ID'],
      );
      final account = await googleSignIn.signIn();
      final auth = await account?.authentication;
      final idToken = auth?.idToken;
      if (idToken == null) {
        throw Exception("No Google ID Token found");
      }

      final response = await _authRepository.loginWithGoogle(idToken);
      if (response.isSuccess && response.result != null) {
        await storage.write('accessToken', response.result!.accessToken);
        await storage.write('refreshToken', response.result!.refreshToken);
        await storage.write('user', {
          ...?response.result!.user,
          'languageId': response.result!.activeLanguage?['languageId'],
          'languageName': response.result!.activeLanguage?['languageName'],
          'languageCode': response.result!.activeLanguage?['languageCode'],
        });

        final surveyRequired = response.result!.activeLanguage == null;
        return {'success': true, 'surveyRequired': surveyRequired};
      } else {
        return {'success': false, 'surveyRequired': false};
      }
    } catch (e) {
      debugPrint('Sign-in error: $e');
      return {'success': false, 'surveyRequired': false};
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

  Future<void> logoutApi(String refreshToken) async {
    try {
      await _authRepository.logout(refreshToken);
    } catch (e) {
      print("Lỗi khi gọi API logout: $e");
    }
  }

  Future<Map<String, dynamic>?> checkSurveyRequired() async {
    try {
      final result = await _authRepository.checkSurveyRequired();
      return result;
    } catch (e) {
      print("checkSurveyRequired error: $e");
      return null;
    }
  }
}
