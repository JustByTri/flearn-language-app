import 'package:flearn_app/features/schedule/model/schedule_model.dart';

import '../model/enrollment_model.dart';

abstract class IScheduleRepository {
  Future<List<TeacherClass>> getTeacherSchedules({String? languageId});
  Future<Map<String, dynamic>> enroll({required String classId});

  Future<List<Enrollment>> getMyEnrollments();
}