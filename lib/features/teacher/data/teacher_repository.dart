import '../model/teacher_profile_model.dart';

abstract class ITeacherRepository {
  Future<TeacherProfile> getTeacherProfile(String teacherId);
}
