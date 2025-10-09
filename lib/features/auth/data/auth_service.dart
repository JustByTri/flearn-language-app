import "dart:async";
import "dart:convert";

import "package:get_storage/get_storage.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

import "../../../config/api_config.dart";
import "../model/login_request.dart";
import "../model/login_response.dart";
import "../model/user.dart";
import '../model/response.dart';
import "auth_repository.dart";

class AuthService implements IAuthRepository {

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginUrl}',);

    try {
      print(" Login request: ${jsonEncode(request.toJson())}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(json);
        print("LoginResponse parsed: isSuccess=${loginResponse
            .isSuccess}, result=${loginResponse.result}");
        return loginResponse;
      } else {
        final error = jsonDecode(response.body);
        print(" API Error: ${error}");
        throw Exception(error["message"] ?? "Login failed");
      }
    } catch (e) {
      print(" Exception in login: $e");
      throw Exception("Login error: $e");
    }
  }

  @override
  Future<LoginResponse> register(String userName,
      String email,
      String password,
      String confirmedPassword,) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.registerUrl}',
    );

    try {
      final registerRequest = {
        "userName": userName,
        "email": email,
        "password": password,
        "confirmPassword": confirmedPassword,
      };
      print(" Register request: ${jsonEncode(registerRequest)}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(registerRequest),
      );

      print(" Register response status: ${response.statusCode}");
      print(" Register response body: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final storage = GetStorage();
        storage.write("registeredEmail", json["email"]);

        final registerResponse = LoginResponse.fromJson(json);
        print(" RegisterResponse parsed: isSuccess=${registerResponse
            .isSuccess}, result=${registerResponse.result}");
        return registerResponse;
      } else {
        final error = jsonDecode(response.body);
        print(" Register API Error: ${error}");
        throw Exception(error["message"] ?? "Registration failed");
      }
    } catch (e) {
      print(" Exception in register: $e");
      throw Exception("Registration error: $e");
    }
  }

  @override
  Future<LoginResponse> loginWithGoogle(String idToken) async{
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.loginGoogle}',
    );
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );
      if (response.statusCode == 200) {
        return LoginResponse.fromJson(
          jsonDecode(response.body),
        );
      } else {
        final errorResponse = jsonDecode(response.body);
        throw Exception(
          errorResponse['message'] ?? 'Login failed',
        );
      }
    }catch(e){
      throw Exception('login error: $e');
    }
  }

  @override
  Future<LoginResponse> confirmEmail(String otp) async {
    final storage = GetStorage();
    final email = storage.read("registeredEmail");

    if (email == null) {
      throw Exception("Email not found in storage. Please register first.");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.confirmEmailUrl}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "email": email,
          "otpCode": otp,
        }),
      );

      return LoginResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      throw Exception('Failed to confirm email: $e');
    }
  }


  @override
  Future<LoginResponse> resendOtp(String email) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resendOtpUrl}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "email": email,
        }),
      );

      return LoginResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      throw Exception('Failed to resend OTP: $e');
    }
  }



  @override
  Future<ResponseModel<User>> fetchProfile() async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileUrl}');
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );
      print("Profile response status: ${response.statusCode}");
      print("Profile response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final userData = jsonResponse['data'];

        return ResponseModel<User>(
          statusCode: response.statusCode,
          message: jsonResponse['message'] ?? 'Success',
          isSuccess: jsonResponse['success'] ?? false,
          result: User.fromJson(userData),
        );
      } else {
        throw Exception("Failed to fetch profile");
      }
    } catch (e) {
      throw Exception("Profile error: $e");
    }
  }


  @override
  Future<bool> forgotPassword(String email) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.forgotPassword}');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"EmailOrUsername": email}),
      );
      print('ForgotPassword response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> resetPassword(String email, String otp, String newPassword, String confirmPassword) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resetPassword}');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }


  Future<Map<String, dynamic>> checkSurveyRequired() async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.checkRequired}');

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );
      print("Check survey required response: ${response.statusCode} - ${response.body}");
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


}