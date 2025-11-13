import '../model/course_progress.dart';
import '../model/lesson_progress_detail.dart';

abstract class ICourseProgressRepository {
  Future<List<CourseProgress>> getMyCourses({int page, int pageSize});
  Future<LessonProgressDetail> getLessonProgressDetail(String lessonId);
}