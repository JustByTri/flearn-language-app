import 'package:get/get.dart';
import '../data/auth_repository.dart';

class ForgotPasswordViewModel extends GetxController {
  final IAuthRepository _authRepository;
  var isLoading = false.obs;

  ForgotPasswordViewModel(this._authRepository);

  Future<bool> forgotPassword(String email) async {
    isLoading.value = true;
    final result = await _authRepository.forgotPassword(email);
    isLoading.value = false;
    return result;
  }

  Future<bool> resetPassword(String email, String otp, String newPassword, String confirmPassword) async {
    isLoading.value = true;
    final result = await _authRepository.resetPassword(email, otp, newPassword, confirmPassword);
    isLoading.value = false;
    return result;
  }
}