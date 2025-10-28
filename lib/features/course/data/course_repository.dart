
import '../model/course.dart';
import '../model/course_lesson.dart';
import '../model/course_unit.dart';


abstract class ICourseRepository{
  Future<List<Course>> getCourse({int page = 1, int pageSize = 4});

  Future<List<CourseUnit>> getCourseUnit(String courseId, {int page, int pageSize});

  Future<List<Lesson>> getCourseLessons(String courseUnitID, {int page, int pageSize});
}