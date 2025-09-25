import "../model/login_request.dart";
import "../model/login_response.dart";
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
}
