import "dart:async";
import "dart:convert";
import "dart:io";
import "package:http/http.dart" as http;
import "package:dio/dio.dart";
import "package:get_storage/get_storage.dart";

import "../../../config/api_config.dart";
import "../model/login_request.dart";
import "../model/login_response.dart";
import "../model/response.dart";
import "../model/roadmap_detail.dart";
import "../model/user.dart";
import "auth_repository.dart";
import "../model/logout_request.dart";

class AuthService implements IAuthRepository {
  final Dio _dio;
  AuthService(this._dio);

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/Auth/login',
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Login error: ${e.message}');
    }
  }

  @override
  Future<LoginResponse> register(
    String userName,
    String email,
    String password,
    String confirmedPassword,
  ) async {
    try {
      final response = await _dio.post(
        '/Auth/register',
        data: {
          "userName": userName,
          "email": email,
          "password": password,
          "confirmPassword": confirmedPassword,
        },
      );
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Registration error: ${e.message}');
    }
  }

  @override
  Future<LoginResponse> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post(
        '/Auth/login-google',
        data: {'idToken': idToken},
      );
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('login error: ${e.message}');
    }
  }
  Future<Map<String, dynamic>> checkSurveyRequired() async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.checkRequired}',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );
      print(
        "Check survey required response: ${response.statusCode} - ${response.body}",
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] as Map<String, dynamic>;
      } else {
        throw Exception("Failed to check survey required");
      }
    } catch (e) {
      throw Exception("Check survey required error: $e");
    }
  }

  @override
  Future<LoginResponse> confirmEmail(String otp) async {
    final storage = GetStorage();
    final email = storage.read("registeredEmail");

    if (email == null) {
      throw Exception("Email not found in storage. Please register first.");
    }

    try {
      final response = await _dio.post(
        '/Auth/confirm-email',
        data: {"email": email, "otpCode": otp},
      );
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to confirm email: ${e.message}');
    }
  }

  @override
  Future<LoginResponse> resendOtp(String email) async {
    try {
      final response = await _dio.post(
        '/Auth/resend-otp',
        data: {"email": email},
      );
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to resend OTP: ${e.message}');
    }
  }

  @override
  Future<ResponseModel<User>> fetchProfile() async {
    try {
      final response = await _dio.get('/Auth/me');
      return ResponseModel<User>.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } on DioException catch (e) {
      throw Exception("Profile error: "+e.message!);
    }
  }

  @override
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/Auth/forgot-password',
        data: {"EmailOrUsername": email},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> resetPassword(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await _dio.post(
        '/Auth/reset-password',
        data: {
          "email": email,
          "otp": otp,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      final request = LogoutRequest(refreshToken: refreshToken);
      await _dio.post(
        '/Auth/logout',
        data: request.toJson(),
      );
      print("Called logout API successfully.");
    } on DioException catch (e) {
      print("Error calling logout API: $e");
    }
  }

  @override
  Future<ResponseModel> updateProfile({
    String? fullName,
    String? userName,
    File? avatar,
  }) async {
    try {
      final formData = FormData.fromMap({
        'FullName': fullName,
        'UserName': userName,
        if (avatar != null)
          'Avatar': await MultipartFile.fromFile(avatar.path),
      });

      final response = await _dio.put(
        '/Auth/profile',
        data: formData,
      );
      return ResponseModel.fromJson(
        response.data,
        (json) => json, // Nếu không có model cụ thể, trả về json
      );
    } on DioException catch (e) {
      throw Exception('Failed to update profile: '+e.message!);
    }
  }

  @override
  Future<ResponseModel> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/Auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      return ResponseModel.fromJson(
        response.data,
        (json) => json, // Nếu không có model cụ thể, trả về json
      );
    } on DioException catch (e) {
      throw Exception('Failed to change password: '+e.message!);
    }
  }

  Future<RoadmapDetailsResponse> fetchRoadmapDetails(String learnerLanguageId) async {
    try {
      final response = await _dio.get(
        '/VoiceAssessment/roadmap-details/$learnerLanguageId',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return RoadmapDetailsResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Lỗi lấy roadmap');
    } on DioException catch (e) {
      throw Exception('Roadmap details error: ${e.message}');
    }
  }

}
