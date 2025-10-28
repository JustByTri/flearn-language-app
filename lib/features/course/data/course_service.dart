import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../model/course.dart';
import '../model/course_unit.dart';
import '../model/course_lesson.dart';
import 'course_repository.dart';

class CourseService implements ICourseRepository {
  @override
  Future<List<Course>> getCourse({int page = 1, int pageSize = 4}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getCourse}')
        .replace(queryParameters: {
      'Page': '$page',
      'PageSize': '$pageSize',
    });

    final res = await http.get(url, headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('getCourse failed ${res.statusCode}: ${res.body}');
    }

    final jsonBody = jsonDecode(res.body);

    final list = (jsonBody['data'] as List?) ?? <dynamic>[];
    return list.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
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