import "dart:async";
import "dart:convert";
import "dart:io";
import "package:http/http.dart" as http;
import "package:dio/dio.dart";
import "package:get_storage/get_storage.dart";

import "../../../config/api_config.dart";
import "../model/login_request.dart";
import "../model/login_response.dart";
import "../model/purchase_history.dart";
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


  @override
  Future<LoginResponse> confirmEmail(String otp) async {
    final storage = GetStorage();
    final email = storage.read("registeredEmail");

    if (email == null) {
      throw Exception("Email not found in storage. Please register first.");
    }

    try {
      final response = await _dio.post(
        '/Auth/verify-otp',
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
  Future<Map<String, dynamic>> resetPassword(
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
          "otpCode": otp,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        },
      );
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Đổi mật khẩu thất bại!'};
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;
        String errorMsg = '';
        if (data is Map && data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          errorMsg = errors.values
              .expand((v) => v as List)
              .map((msg) => msg.toString())
              .join('\n');
        } else if (data['title'] != null) {
          errorMsg = data['title'].toString();
        } else {
          errorMsg = 'Đổi mật khẩu thất bại!';
        }
        return {
          'success': false,
          'error': errorMsg,
        };
      }
      return {
        'success': false,
        'error': e.message ?? 'Đổi mật khẩu thất bại!',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
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
      // If server responded with body, convert it to ResponseModel so caller can read message
      if (e.response != null && e.response!.data != null && e.response!.data is Map<String, dynamic>) {
        try {
          return ResponseModel.fromJson(e.response!.data as Map<String, dynamic>, (json) => json);
        } catch (err) {
          // fallback
          return ResponseModel<dynamic>(
            statusCode: e.response?.statusCode ?? 0,
            message: e.response?.data['message']?.toString() ?? e.message ?? 'Đã có lỗi xảy ra',
            isSuccess: false,
            result: null,
          );
        }
      }

      // No server body: return a generic failed ResponseModel
      return ResponseModel<dynamic>(
        statusCode: e.response?.statusCode ?? 0,
        message: e.message ?? 'Đã có lỗi xảy ra',
        isSuccess: false,
        result: null,
      );
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

  @override
  Future<Map<String, dynamic>?> purchaseSubscription(String planName) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/subscriptions/purchase');
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({"plan": planName}),
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return jsonBody;
      }
      return null;
    } catch (e) {
      print('purchaseSubscription error: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getPurchaseHistory({
    int page = 1,
    int pageSize = 10,
    String sortBy = 'newest',
  }) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/purchases?Page=$page&PageSize=$pageSize&SortBy=$sortBy');
    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.toString().isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('getPurchaseHistory failed ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRefundRequests() async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/Refund/my-requests');
    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body['status'] == 'success' && body['data'] != null) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
    }
    return [];
  }


}
