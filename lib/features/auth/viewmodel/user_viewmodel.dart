import 'package:flearn_app/features/auth/model/user.dart';
import 'package:get/get.dart';

import '../data/auth_repository.dart';

class UserViewModel extends GetxController {
  final IAuthRepository _authRepository;
  UserViewModel(this._authRepository);
  var user = Rxn<User>();
  var isLoading = false.obs;
  var errorMessage = RxnString();

  Future<void> fetchUserInfo() async {
    try {
      isLoading.value = true;
      final response = await _authRepository.fetchProfile();
      user.value = response.result;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}