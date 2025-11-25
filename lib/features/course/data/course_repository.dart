
import '../../auth/model/course_popular.dart';
import '../model/all_exercise_submit.dart';
import '../model/course.dart';
import '../model/course_access.dart';
import '../model/course_detail.dart';
import '../model/course_exercise.dart';
import '../model/course_lesson.dart';
import '../model/course_unit.dart';
import '../model/curriculum.dart';
import '../model/exercise_submission_detail.dart';
import '../model/lesson_tracking.dart';


abstract class ICourseRepository{
  Future<List<Course>> getCourse({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? searchTerm,
    String? lang,
    String? sortBy,
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

  Future<String?> submitExercise({
    required String exerciseId,
    required String audioFilePath,
  });

  Future<Exercise> getExerciseDetail(String exerciseId);

  Future<ExerciseSubmissionDetail?> fetchSubmissionDetail(String submissionId);

  Future<List<ExerciseSubmission>> getExerciseSubmissions({
    required String exerciseId,
    int pageNumber,
    int pageSize,
  });

  Future<Map<String, dynamic>?> enrollFreeCourse(String courseId);

  Future<List<CoursePopular>> getCoursePopularByLang({int count = 10, String? languageId});
}