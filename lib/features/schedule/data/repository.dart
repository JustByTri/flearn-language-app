import 'package:flearn_app/features/schedule/model/enrollment_model.dart';

import '../model/schedule_model.dart';

abstract class IScheduleRepository {
  Future<List<TeacherClass>> getTeacherSchedules({String? languageId});

  Future<Map<String, dynamic>> bookClass(String classId);

  Future<List<Enrollment>> getMyEnrollments();
}
