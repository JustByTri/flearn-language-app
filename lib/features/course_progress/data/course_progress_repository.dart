import '../model/course_progress.dart';

abstract class ICourseProgressRepository {
  Future<List<CourseProgress>> getMyCourses({int page, int pageSize});
}