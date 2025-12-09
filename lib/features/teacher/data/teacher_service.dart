import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../model/teacher_profile_model.dart';
import 'teacher_repository.dart';

class TeacherService implements ITeacherRepository {
  final Dio _dio;

  TeacherService(this._dio);

  @override
  Future<TeacherProfile> getTeacherProfile(String teacherId) async {
    try {
      final response = await _dio.get('/$teacherId/profile');
      return TeacherProfile.fromJson(response.data);
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> submitTeacherReview({
    required String teacherId,
    required int rating,
    required String comment,
  }) async {
    final token = GetStorage().read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/teacher-reviews/teachers/$teacherId');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );

    Map<String, dynamic> body = {};
    try { body = jsonDecode(res.body) as Map<String, dynamic>; } catch (_) {}

    final status = (body['status'] ?? (res.statusCode == 200 || res.statusCode == 201 ? 'success' : 'fail')).toString();
    final code = body['code'] is int ? body['code'] as int : res.statusCode;
    final message = (body['message'] ?? '').toString();
    final data = body['data'] as Map<String, dynamic>?;
    final errors = body['errors'] as Map<String, dynamic>?;

    return {
      'status': status.toLowerCase(),
      'code': code,
      'message': message,
      'data': data ?? errors,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getTeacherReviews({
    required String teacherId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/teacher-reviews/teachers/$teacherId?PageNumber=$page&PageSize=$pageSize');
    final res = await http.get(url);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data.map((e) => e as Map<String, dynamic>).toList();
  }


}
