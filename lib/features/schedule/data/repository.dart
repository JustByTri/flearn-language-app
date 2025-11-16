import 'package:flearn_app/features/schedule/model/enrollment_model.dart';

import '../model/schedule_model.dart';

abstract class IScheduleRepository {
  Future<List<TeacherClass>> getTeacherSchedules({String? languageId});

  Future<Map<String, dynamic>> bookClass(String classId);

  Future<List<Enrollment>> getMyEnrollments();

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
  });

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
  });

  Future<List<Teacher>> getAllTeachers();

  Future<List<Program>> getPrograms(String languageId);
}
