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


  Future<Map<String, dynamic>> submitRefundRequest({
    required String enrollmentID,
    required String classID,
    required String className,
    required int requestType,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountHolderName,
    required String reason,
  });

  // Added APIs used by ClassSearchViewModel
  Future<List<Teacher>> getAllTeachers();

  Future<List<Program>> getPrograms(String languageId);

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
  });

  Future<Map<String, dynamic>> updateClassRefundBankInfo({
    required String refundRequestId,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountHolderName,
  });

}
