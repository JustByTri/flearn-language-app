import "dart:async";
import "dart:convert";

import "package:http/http.dart" as http;

import "../../../config/api_config.dart";
import "../../../utils/decode_token.dart";
import "../model/login_request.dart";
import "../model/login_response.dart";
import "../model/user.dart";
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
  Future<LoginResponse> confirmEmail(String otp) async {
    final tokendata = getDecodedAccessToken();
    if (tokendata == null) {
      throw Exception("Invalid token");
    }
    String? userId = tokendata['Id'];

    final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.confirmEmailUrl}?userID=$userId');

    try {
      final response = await http.post(url);
      return LoginResponse.fromJson(
        jsonDecode(response.body),
      );
    } catch (e) {
      throw Exception('Failed to confirm email: $e');
    }
  }
}