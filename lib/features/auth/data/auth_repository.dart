import 'dart:io';

import "../model/login_request.dart";
import "../model/login_response.dart";
import "../model/purchase_history.dart";
import "../model/response.dart";
import '../model/logout_request.dart';
import "../model/roadmap_detail.dart";
import "../model/user.dart";

abstract class IAuthRepository {
  Future<LoginResponse> login(LoginRequest request);
  Future<LoginResponse> register(
      String userName,
      String email,
      String password,
      String confirmedPassword,
      );
  Future<void> logout(String refreshToken);
  Future<LoginResponse> confirmEmail(String otp);

  Future<LoginResponse> resendOtp(String email);

  Future<ResponseModel<User>> fetchProfile();

  Future<LoginResponse> loginWithGoogle(String idToken);

  Future<bool> forgotPassword(String email);
  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword, String confirmPassword);

  Future<ResponseModel> updateProfile({
    String? fullName,
    String? userName,
    File? avatar,
  });

  Future<ResponseModel> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<RoadmapDetailsResponse> fetchRoadmapDetails(String learnerLanguageId);

  Future<Map<String, dynamic>?> purchaseSubscription(String planName);

  Future<Map<String, dynamic>?> getPurchaseHistory({
    int page = 1,
    int pageSize = 10,
    String sortBy = 'newest',
  });

  Future<List<Map<String, dynamic>>> fetchRefundRequests();
}
