import "package:flearn_app/features/survey/model/survey_status.dart";

import "../model/login_request.dart";
import "../model/login_response.dart";
import "../model/response.dart";
import "../../survey/model/survey_option.dart";
import "../../survey/model/survey_request.dart";
import "../../topic/model/topic.dart";
import "../model/user.dart";

abstract class IAuthRepository {
  Future<LoginResponse> login(LoginRequest request);
  Future<LoginResponse> register(
      String userName,
      String email,
      String password,
      String confirmedPassword,
      );

  Future<LoginResponse> confirmEmail(String otp);

  Future<LoginResponse> resendOtp(String email);

  Future<ResponseModel<User>> fetchProfile();

  Future<LoginResponse> loginWithGoogle(String idToken);



  Future<bool> forgotPassword(String email);
  Future<bool> resetPassword(String email, String otp, String newPassword, String confirmPassword);

  Future<SurveyStatus?> hasCompletedSurvey();

}
