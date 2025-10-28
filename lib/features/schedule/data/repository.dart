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
}
