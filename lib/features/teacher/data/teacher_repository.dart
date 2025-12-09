import '../model/teacher_profile_model.dart';

abstract class ITeacherRepository {
  Future<TeacherProfile> getTeacherProfile(String teacherId);

  Future<Map<String, dynamic>> submitTeacherReview({
    required String teacherId,
    required int rating,
    required String comment,
  });

  Future<List<Map<String, dynamic>>> getTeacherReviews({
    required String teacherId,
    int page = 1,
    int pageSize = 10,
  });
}
