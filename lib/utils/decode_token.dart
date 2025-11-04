import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

bool isAccessTokenValid() {
  final storage = GetStorage();
  final accessToken = storage.read('accessToken');

  if (accessToken != null &&
      accessToken is String &&
      accessToken.isNotEmpty) {
    try {
      return !JwtDecoder.isExpired(accessToken);
    } catch (e) {
      debugPrint('[Debug] Error decoding token: $e');
      return false;
    }
  } else {
    debugPrint('[Debug] Access token not found or empty');
    return false;
  }
}

Map<String, dynamic>? getDecodedAccessToken() {
  final storage = GetStorage();
  final accessToken = storage.read('accessToken');

  if (accessToken != null &&
      accessToken is String &&
      accessToken.isNotEmpty) {
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(
        accessToken,
      );
      return decodedToken;
    } catch (e) {
      debugPrint('[Debug] Error decoding token: $e');
      return null;
    }
  } else {
    debugPrint('[Debug] Access token not found or empty');
    return null;
  }
}