class LoginResponse {
  final bool isSuccess;
  final String? message;
  final LoginResult? result;

  LoginResponse({
    required this.isSuccess,
    this.message,
    this.result,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      isSuccess: json['success'] ?? false,
      message: json['message'],
      result: json['data'] != null ? LoginResult.fromJson(json['data']) : null,
    );
  }
}

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final String? accessTokenExpires;
  final String? refreshTokenExpires;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? activeLanguage;
  final List<dynamic>? roles;

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpires,
    this.refreshTokenExpires,
    this.user,
    this.activeLanguage,
    this.roles,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      accessTokenExpires: json['accessTokenExpires'],
      refreshTokenExpires: json['refreshTokenExpires'],
      user: json['user'],
      activeLanguage: json['activeLanguage'],
      roles: json['roles'],
    );
  }
}