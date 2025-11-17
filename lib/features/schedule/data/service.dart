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
  Future<Map<String, dynamic>> submitRefundRequest({
    required String enrollmentID,
    required String classID,
    required String className,
    required int requestType,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountHolderName,
    required String reason,
  }) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/Refund/submit');
    final body = {
      "enrollmentID": enrollmentID,
      "classID": classID,
      "className": className,
      "requestType": requestType,
      "bankName": bankName,
      "bankAccountNumber": bankAccountNumber,
      "bankAccountHolderName": bankAccountHolderName,
      "reason": reason,
    };
    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
      final jsonBody = jsonDecode(response.body);
      if (response.statusCode == 200 && jsonBody['success'] == true) {
        return jsonBody['data'] as Map<String, dynamic>;
      } else {
        throw Exception(jsonBody['message'] ?? 'Gửi đơn hoàn tiền thất bại');
      }
    } catch (e) {
      print('[ScheduleService] submitRefundRequest Exception: $e');
      rethrow;
    }
  }

  @override
  Future<List<Teacher>> getAllTeachers() async {
    final accessToken = _getToken();
    final url = Uri.parse('https://f-learn.app/api/teachers/all');
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
        return data.map((e) => Teacher.fromJson(e as Map<String, dynamic>)).toList();
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
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((e) => Program.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load programs: ${response.body}');
      }
    } catch (e) {
      print('[ScheduleService] getPrograms Exception: $e');
      rethrow;
    }
  }

  @override
  Future<List<ClassSearchResult>> searchClasses({
    required String languageId,
    String? teacherId,
    String? programId,
    String? keyword,
    String? status,
    int? page,
    int? pageSize,
    String? from,
    String? to,
  }) async {
    final accessToken = _getToken();
    final params = <String, String>{
      if (languageId.isNotEmpty) 'languageId': languageId,
      if (teacherId != null && teacherId.isNotEmpty) 'teacherId': teacherId,
      if (programId != null && programId.isNotEmpty) 'programId': programId,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (status != null && status.isNotEmpty) 'status': status,
      if (page != null) 'page': page.toString(),
      if (pageSize != null) 'pageSize': pageSize.toString(),
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
    final uri = Uri.https('f-learn.app', '/api/classes/public/search', params);
    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((e) => ClassSearchResult.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to search classes: ${response.body}');
      }
    } catch (e) {
      print('[ScheduleService] searchClasses Exception: $e');
      rethrow;
    }
  }

}
