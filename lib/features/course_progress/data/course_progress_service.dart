import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../model/course_progress.dart';
import '../model/lesson_progress_detail.dart';
import 'course_progress_repository.dart';

class CourseProgressService implements ICourseProgressRepository {
  @override
  Future<List<CourseProgress>> getMyCourses({int page = 1, int pageSize = 10}) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/enrollments/my-courses?Page=$page&PageSize=$pageSize');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );
    print('getMyCourses: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final data = jsonBody['data'] as List<dynamic>? ?? [];

      return data.map((item) => CourseProgress.fromJson(item)).toList();
    } else {
      throw Exception('getMyCourses failed: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<LessonProgressDetail> getLessonProgressDetail(String lessonId) async {
    print('getLessonProgressDetail: $lessonId');
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/lesson-progress/lessons/$lessonId/progress');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );
    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return LessonProgressDetail.fromJson(jsonBody['data']);
    } else {
      throw Exception('getLessonProgressDetail failed: ${response.statusCode} ${response.body}');
    }
  }
}