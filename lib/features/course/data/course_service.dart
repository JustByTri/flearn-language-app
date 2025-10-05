import 'dart:convert';

import 'package:flearn_app/features/course/model/course.dart';
import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import 'course_repository.dart';

class CourseService implements ICourseRepository {
  @override
  Future<List<Course>> getCourse() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getCourse}');
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      print('CourseService response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        print('CourseService data: $data');
        return data.map((item) => Course.fromJson(item)).toList();
      } else {
        print('getCourse failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('getCourse error: $e');
      return [];
    }
  }
}