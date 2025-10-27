// lib/core/services/dio_interceptor.dart

import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class DioInterceptor extends Interceptor {
  // Hàm này được gọi TRƯỚC KHI một request được gửi đi
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('--> ${options.method.toUpperCase()} ${options.baseUrl}${options.path}');

    // Lấy token từ GetStorage
    final box = GetStorage();
    final token = box.read('accessToken');

    // Nếu có token, đính kèm nó vào header Authorization
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      debugPrint('Authorization Header: Bearer ...${token.substring(token.length - 6)}');
    }

    // Tiếp tục gửi request đi
    super.onRequest(options, handler);
  }

  // Hàm này được gọi KHI có một response trả về (thành công)
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('<-- ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}');
    debugPrint('Response data: ${response.data}');
    super.onResponse(response, handler);
  }

  // Hàm này được gọi KHI có lỗi xảy ra
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('## DioException Error:');
    debugPrint('<-- ${err.message}');
    if (err.response != null) {
      debugPrint('<-- ${err.response?.statusCode} ${err.response?.statusMessage}');
      debugPrint('Response data: ${err.response?.data}');
    }
    super.onError(err, handler);
  }
}
