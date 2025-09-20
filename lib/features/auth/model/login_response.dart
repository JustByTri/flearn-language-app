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

  LoginResult({
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpires,
    this.refreshTokenExpires,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      accessTokenExpires: json['accessTokenExpires'],
      refreshTokenExpires: json['refreshTokenExpires'],
    );
  }
}