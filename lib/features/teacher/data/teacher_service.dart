import 'package:dio/dio.dart';

import '../model/teacher_profile_model.dart';
import 'teacher_repository.dart';

class TeacherService implements ITeacherRepository {
  final Dio _dio;

  TeacherService(this._dio);

  @override
  Future<TeacherProfile> getTeacherProfile(String teacherId) async {
    try {
      final response = await _dio.get('/$teacherId/profile');
      return TeacherProfile.fromJson(response.data);
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
}
