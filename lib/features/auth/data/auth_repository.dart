import "../model/user.dart";

abstract class IAuthRepository {
  Future<User?> login(String email, String password);
  Future<User?> register(
    String email,
    String password,
    String name,
  );
}
