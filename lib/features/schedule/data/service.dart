import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flearn_app/features/schedule/model/schedule_model.dart';
import '../model/enrollment_model.dart';
import 'repository.dart';

class ScheduleService implements IScheduleRepository {
  @override
  Future<List<TeacherClass>> getTeacherSchedules({String? languageId}) async {
    final accessToken = GetStorage().read('accessToken');
    final query = languageId != null ? '?languageId=$languageId' : '';
    final url = Uri.parse('https://f-learn.app/api/student/classes/available$query');

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => TeacherClass.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load teacher schedules: ${response.body}');
      }
    } catch (e) {
      print('[ScheduleService] getTeacherSchedules Exception: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> bookClass(String classId) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/student/classes/$classId/enroll');
    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body as Map<String, dynamic>;
      } else {
        // Try to get a meaningful error message from the API response
        final message = body['message'] ?? 'Failed to enroll';
        throw Exception(message);
      }
    } catch (e) {
      print('[ScheduleService] bookClass Exception: $e');
      rethrow;
    }
  }

  @override
  Future<List<Enrollment>> getMyEnrollments() async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/student/classes/my-enrollments?page=1&pageSize=10');
    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => Enrollment.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load enrollments: ${response.body}');
      }
    } catch (e) {
      print('[ScheduleService] getMyEnrollments Exception: $e');
      rethrow;
    }
  }
}
