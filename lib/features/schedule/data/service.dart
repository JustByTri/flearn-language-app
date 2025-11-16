import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flearn_app/features/schedule/model/schedule_model.dart';
import '../model/enrollment_model.dart';
import 'repository.dart';

class ScheduleService implements IScheduleRepository {
  String? _getToken() {
    final box = GetStorage();
    return box.read('accessToken') as String? ?? box.read('token') as String?;
  }

  @override
  Future<List<TeacherClass>> getTeacherSchedules({String? languageId}) async {
    final accessToken = _getToken();
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
    final accessToken = _getToken();
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
    final accessToken = _getToken();
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

  @override
  Future<bool> confirmPaymentCallback({
    required String transactionId,
    required int amount,
    required String classId,
    required String studentId,
    String status = 'PAID',
    String paymentMethod = 'PAYOS',
    String? paidAtIso,
    String? signature,
    String? description,
  }) async {
    final accessToken = _getToken();
    final url = Uri.parse('https://f-learn.app/api/student/classes/payment-callback');
    try {
      final body = {
        "transactionId": transactionId,
        "status": status,
        "amount": amount,
        "signature": signature ?? "",
        "paidAt": paidAtIso ?? DateTime.now().toIso8601String(),
        "paymentMethod": paymentMethod,
        "description": description ?? "",
        "studentID": studentId,
        "classID": classId,
      };
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
      final jsonBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return jsonBody['success'] == true;
      } else {
        print('[ScheduleService] confirmPaymentCallback failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('[ScheduleService] confirmPaymentCallback Exception: $e');
      return false;
    }
  }

  @override
  Future<List<ClassSearchResult>> searchClasses({
    required String languageId,
    String? teacherId,
    String? programId,
    String? keyword,
    String? status,
    String? from,
    String? to,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParameters = <String, String>{
      'languageId': languageId,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (teacherId != null && teacherId.isNotEmpty) {
      queryParameters['teacherId'] = teacherId;
    }
    if (programId != null && programId.isNotEmpty) {
      queryParameters['programId'] = programId;
    }
    if (keyword != null && keyword.isNotEmpty) {
      queryParameters['keyword'] = keyword;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (from != null && from.isNotEmpty) {
      queryParameters['from'] = from;
    }
    if (to != null && to.isNotEmpty) {
      queryParameters['to'] = to;
    }

    final uri = Uri.parse('https://f-learn.app/api/classes/public/search').replace(queryParameters: queryParameters);
    print('[ScheduleService] searchClasses URI: $uri');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => ClassSearchResult.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search classes: ${response.body}');
      }
    } catch (e) {
      print('[ScheduleService] searchClasses Exception: $e');
      rethrow;
    }
  }

  @override
  Future<List<Teacher>> getAllTeachers() async {
    final url = Uri.parse('https://f-learn.app/api/teachers/all');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => Teacher.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load teachers: ${response.body}');
      }
    } catch (e) {
      print('[ScheduleService] getAllTeachers Exception: $e');
      rethrow;
    }
  }

  @override
  Future<List<Program>> getPrograms(String languageId) async {
    final accessToken = _getToken();
    final url = Uri.parse('https://f-learn.app/api/VoiceAssessment/programs/$languageId');
    try {
      final response = await http.get(
        url,
        headers: accessToken != null
            ? {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json',
              }
            : null,
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => Program.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load programs: ${response.body}');
      }
    } catch (e) {
      print('[ScheduleService] getPrograms Exception: $e');
      rethrow;
    }
  }
}
