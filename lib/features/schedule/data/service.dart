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
    final url = Uri.parse(
      'https://f-learn.app/api/student/classes/available?${languageId != null ? '?languageId=$languageId' : ''}',
    );
    print('[ScheduleService] GET $url');
    print('[ScheduleService] accessToken: $accessToken');
    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );
      print('[ScheduleService] Response status: ${response.statusCode}');
      print('[ScheduleService] Response body: ${response.body}');
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        print('[ScheduleService] Parsed ${data.length} schedules');
        return data.map((item) => TeacherClass.fromJson(item)).toList();
      } else {
        print('[ScheduleService] Error: ${response.body}');
        throw Exception('Failed to load teacher schedules: ${response.body}');
      }
    } catch (e) {
      print('[ScheduleService] Exception: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> enroll({required String classId}) async {
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

      print('[ScheduleService] Enroll Response body: ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to enroll: ${response.body}');
      }
    } catch (e) {
      print('[ScheduleService] Enroll Exception: $e');
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
      print('[ScheduleService] MyEnrollments Response: ${response.body}');
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => Enrollment.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load enrollments: ${response.body}');
      }
    } catch (e) {
      print('[ScheduleService] MyEnrollments Exception: $e');
      rethrow;
    }
  }

}