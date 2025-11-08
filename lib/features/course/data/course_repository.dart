
import '../model/course.dart';
import '../model/course_access.dart';
import '../model/course_detail.dart';
import '../model/course_lesson.dart';
import '../model/course_unit.dart';


abstract class ICourseRepository{
  Future<List<Course>> getCourse({
    int page,
    int pageSize,
    String? status,
    String? searchTerm,
    String? lang,
  });

  Future<List<CourseUnit>> getCourseUnit(String courseId, {int page, int pageSize});

  Future<List<Lesson>> getCourseLessons(String courseUnitID, {int page, int pageSize});

  Future<Map<String, dynamic>> createPurchase({
    required String courseId,
    int paymentMethod,
    String? promotionCode,
  });

  Future<Map<String, dynamic>> payPurchase(String purchaseId);

  Future<CourseDetail> getCourseDetail(String courseId);

  Future<bool> enrollCourse(String courseId);

  Future<CourseAccess> getCourseAccess(String courseId);

  Future<Lesson> getLessonById(String lessonId);
}