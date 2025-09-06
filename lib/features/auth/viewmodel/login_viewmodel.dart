import 'package:flutter/material.dart';

import '../data/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final IAuthRepository _authRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  LoginViewModel(this._authRepository);

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authRepository.login(
        email,
        password,
      );
      debugPrint("Login success: ${user?.email}");
      return true;
    } catch (e) {
      debugPrint("Login failed: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
