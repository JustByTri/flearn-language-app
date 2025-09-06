import "dart:async";

import "../model/user.dart";
import "auth_repository.dart";

class AuthService implements IAuthRepository {
  @override
  Future<User?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email == "test@example.com" &&
        password == "123456") {
      return User(id: "1", email: email, name: "Test User");
    } else {
      throw Exception("Invalid email or password");
    }
  }

  @override
  Future<User?> register(
    String email,
    String password,
    String name,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    return User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
    );
  }
}
