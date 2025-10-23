import 'dart:convert';

import 'package:flearn_app/features/course/model/course.dart';
import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../model/course_lesson.dart';
import '../model/course_unit.dart';
import 'course_repository.dart';

class CourseService implements ICourseRepository {
  @override
  Future<List<Course>> getCourse({int page = 1, int pageSize = 10}) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.getCourse}?status=published&page=$page&pageSize=$pageSize',
    );
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

  @override
  Future<List<CourseUnit>> getCourseUnit(String courseId, {int page = 1, int pageSize = 10}) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/courses/$courseId/units?Page=$page&PageSize=$pageSize',
    );
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => CourseUnit.fromJson(item)).toList();
      } else {
        print('getCourseUnit failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('getCourseUnit error: $e');
      return [];
    }
  }

  @override
  Future<List<Lesson>> getCourseLessons(String courseUnitID, {int page = 1, int pageSize = 10}) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/units/$courseUnitID/lessons?page=$page&pageSize=$pageSize',
    );
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => Lesson.fromJson(item)).toList();
      } else {
        print('getCourseLessons failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('getCourseLessons error: $e');
      return [];
    }
  }
}