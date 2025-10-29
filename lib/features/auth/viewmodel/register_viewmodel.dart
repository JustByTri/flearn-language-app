import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/auth_repository.dart';

class RegisterViewModel extends GetxController {
  final IAuthRepository _authRepository;
  final storage = GetStorage();
  var isLoading = false.obs;

  RegisterViewModel(this._authRepository);

  Future<Map<String, dynamic>> register(
      String userName,
      String email,
      String password,
      String confirmedPassword,
      ) async {
    try {
      isLoading.value = true;
      print("Starting registration with userName: $userName, email: $email");

      final response = await _authRepository.register(
        userName,
        email,
        password,
        confirmedPassword,
      );

      print("Register response - isSuccess: ${response.isSuccess}");
      print("Register response - message: ${response.message}");
      print("Register response - result: ${response.result}");

      if (response.isSuccess) {
        // store registered email for confirm flow
        try {
          await storage.write('registeredEmail', email);
        } catch (e) {
          print('Failed to write registeredEmail to storage: $e');
        }

        return {'success': true, 'message': response.message ?? 'Đăng ký thành công'};
      } else {
        return {'success': false, 'message': response.message ?? 'Đăng ký thất bại'};
      }

    } catch (e) {
      print(" Registration exception: $e");
      return {'success': false, 'message': 'Lỗi khi đăng ký: $e'};
    } finally {
      isLoading.value = false;
    }
  }
}