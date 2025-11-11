
import '../../auth/model/course_popular.dart';
import '../model/course.dart';
import '../model/course_access.dart';
import '../model/course_detail.dart';
import '../model/course_exercise.dart';
import '../model/course_lesson.dart';
import '../model/course_unit.dart';
import '../model/curriculum.dart';
import '../model/lesson_tracking.dart';


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

  Future<Map<String, dynamic>?> enrollCourse(String courseId);

  Future<Curriculum> getEnrollmentCurriculum(String enrollmentId);

  Future<CourseAccess> getCourseAccess(String courseId);

  Future<Lesson> getLessonById(String lessonId);

  Future<List<Exercise>> getLessonExercises(String lessonId, {int page, int pageSize});

  Future<void> trackLessonActivity({
    required String lessonId,
    required int logType,
    required int durationMinutes,
    required String metadata,
  });

  Future<LessonProgress> startLesson({
    required String unitId,
    required String lessonId,
  });

  Future<List<CoursePopular>> getCoursePopular({int count});
}