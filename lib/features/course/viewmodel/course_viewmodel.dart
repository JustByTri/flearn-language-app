import 'package:flearn_app/features/course/data/course_repository.dart';
import 'package:flearn_app/features/course/model/course.dart';
import 'package:get/get.dart';
import '../../auth/model/course_popular.dart';
import '../model/all_exercise_submit.dart';
import '../model/course_access.dart';
import '../model/course_detail.dart';
import '../model/course_exercise.dart';
import '../model/course_lesson.dart';
import '../model/course_unit.dart';
import '../model/curriculum.dart';
import '../model/exercise_submission_detail.dart';
import '../model/lesson_tracking.dart';

class CourseViewModel extends GetxController {
  final ICourseRepository _courseRepository;
  var isLoadingCourse = false.obs;
  var courses = <Course>[].obs;
  var totalItems = 0.obs;
  // paging state
  final currentPage = 1.obs;
  final int pageSize = 4;
  final hasMoreCourses = true.obs;

  var isLoadingUnit = false.obs;
  var units = <CourseUnit>[].obs;

  var isLoadingLesson = false.obs;
  var lessons = <Lesson>[].obs;

  CourseViewModel(this._courseRepository);

  // New method to fetch courses with language and search support
  Future<void> fetchCoursesWithLanguage({
    String? lang,
    String? searchTerm,
    String? sortBy,
    bool isRefresh = false,
  }) async {
    if (isLoadingCourse.value) return;
    try {
      isLoadingCourse.value = true;
      final int pageToFetch = isRefresh ? 1 : currentPage.value;
      print('CourseViewModel: Fetching page $pageToFetch with lang: $lang, search: $searchTerm, sortBy: $sortBy');

      final List<Course> list = await _courseRepository.getCourse(
        page: pageToFetch,
        pageSize: 10, // Show more courses on home screen
        status: 'Published',
        lang: lang,
        searchTerm: searchTerm,
        sortBy: sortBy,
      );
      print('CourseViewModel: Fetched ${list.length} courses');

      if (isRefresh) {
        courses.assignAll(list);
        currentPage.value = 2;
        hasMoreCourses.value = list.length == 10;
      } else {
        if (list.isNotEmpty) courses.addAll(list);
        currentPage.value = currentPage.value + 1;
        hasMoreCourses.value = list.length == 10;
      }
    } catch (e) {
      print('CourseViewModel: fetchCoursesWithLanguage error: $e');
      // Clear courses on error to show empty state
      if (isRefresh) {
        courses.clear();
      }
      hasMoreCourses.value = false;
    } finally {
      isLoadingCourse.value = false;
    }
  }

  // Replace or add this method
  Future<void> fetchMoreCourses({bool isRefresh = false}) async {
    if (isLoadingCourse.value) return;
    try {
      isLoadingCourse.value = true;
      final int pageToFetch = isRefresh ? 1 : currentPage.value;
      print('CourseViewModel: Fetching page $pageToFetch with pageSize $pageSize, isRefresh: $isRefresh');
      final List<Course> list = await _courseRepository.getCourse(
        page: pageToFetch,
        pageSize: pageSize,
        status: 'Published',
        sortBy: null,
      );
      print('CourseViewModel: Fetched ${list.length} courses from page $pageToFetch');

      if (isRefresh) {
        courses.assignAll(list);
        currentPage.value = 2;
        hasMoreCourses.value = list.length == pageSize;
        print('CourseViewModel: Refresh done. Total courses: ${courses.length}, hasMore: ${hasMoreCourses.value}');
      } else {
        if (list.isNotEmpty) courses.addAll(list);
        currentPage.value = currentPage.value + 1;
        hasMoreCourses.value = list.length == pageSize;

        print('CourseViewModel: Added ${list.length} courses. Total courses: ${courses.length}, currentPage: ${currentPage.value}, hasMore: ${hasMoreCourses.value}');
      }
    } catch (e) {
      print('CourseViewModel: fetchMoreCourses error: $e');
      hasMoreCourses.value = false;
    } finally {
      isLoadingCourse.value = false;
    }
  }


  Future<void> fetchPage(int page) async {
    await fetchMoreCourses(isRefresh: page == 1);
  }

  // Optional helpers (keep for compatibility)
  Future<void> nextPage() async {
    if (!hasMoreCourses.value) return;
    await fetchMoreCourses();
  }

  Future<void> prevPage() async {
    // not used in infinite scroll UI — keep as noop or implement if needed
    final prev = (currentPage.value - 2);
    if (prev >= 1) {
      await fetchPage(prev);
    }
  }

  Future<void> fetchCourseUnits(String courseId, {int page = 1, int pageSize = 10}) async {
    try {
      isLoadingUnit.value = true;
      final list = await _courseRepository.getCourseUnit(courseId, page: page, pageSize: pageSize);
      units.assignAll(list);
      print('Gọi getCourseUnit với courseId: $courseId');
    } catch (e) {
      print('fetchCourseUnits error: $e');
    } finally {
      isLoadingUnit.value = false;
    }
  }

  Future<void> fetchCourseLessons(String courseUnitID, {int page = 1, int pageSize = 10}) async {
    try {
      isLoadingLesson.value = true;
      final list = await _courseRepository.getCourseLessons(courseUnitID, page: page, pageSize: pageSize);
      lessons.assignAll(list);
    } catch (e) {
      print('fetchCourseLessons error: $e');
    } finally {
      isLoadingLesson.value = false;
    }
  }

  Future<Map<String, dynamic>?> createPurchase({
    required String courseId,
    int paymentMethod = 1,
    String? promotionCode,
  }) async {
    try {
      return await _courseRepository.createPurchase(
        courseId: courseId,
        paymentMethod: paymentMethod,
        promotionCode: promotionCode,
      );
    } catch (e) {
      print('CourseViewModel: createPurchase error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> payPurchase(String purchaseId) async {
    try {
      return await _courseRepository.payPurchase(purchaseId);
    } catch (e) {
      print('CourseViewModel: payPurchase error: $e');
      return null;
    }
  }

  var isLoadingDetail = false.obs;
  var courseDetail = Rxn<CourseDetail>();

  Future<void> fetchCourseDetail(String courseId) async {
    try {
      isLoadingDetail.value = true;
      final detail = await _courseRepository.getCourseDetail(courseId);
      courseDetail.value = detail;
    } catch (e) {
      print('CourseViewModel: fetchCourseDetail error: $e');
      courseDetail.value = null;
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<Map<String, dynamic>?> enrollCourse(String courseId) async {
    try {
      return await _courseRepository.enrollCourse(courseId);
    } catch (e) {
      print('enrollCourse error: $e');
      return null;
    }
  }

  var courseAccess = Rxn<CourseAccess>();

  Future<void> fetchCourseAccess(String courseId) async {
    try {
      final access = await _courseRepository.getCourseAccess(courseId);
      courseAccess.value = access;
    } catch (e) {
      print('CourseViewModel: fetchCourseAccess error: $e');
      courseAccess.value = null;
    }
  }

  Future<Lesson?> fetchLessonById(String lessonId) async {
    try {
      return await _courseRepository.getLessonById(lessonId);
    } catch (e) {
      print('fetchLessonById error: $e');
      return null;
    }
  }


  var exercises = <Exercise>[].obs;
  var isLoadingExercises = false.obs;

  Future<void> fetchLessonExercises(String lessonId, {int page = 1, int pageSize = 10}) async {
    isLoadingExercises.value = true;
    try {
      final result = await _courseRepository.getLessonExercises(lessonId, page: page, pageSize: pageSize);
      exercises.assignAll(result);
    } catch (e) {
      exercises.clear();
    } finally {
      isLoadingExercises.value = false;
    }
  }

  Future<void> trackLessonActivity({
    required String lessonId,
    required int logType,
    required int durationMinutes,
    required String metadata,
  }) async {
    try {
      await _courseRepository.trackLessonActivity(
        lessonId: lessonId,
        logType: logType,
        durationMinutes: durationMinutes,
        metadata: metadata,
      );
    } catch (e) {
      print('trackLessonActivity error: $e');
    }
  }

  var isLoadingCurriculum = false.obs;
  var curriculum = Rxn<Curriculum>();
  var curriculumError = RxnString();

  Future<void> fetchCurriculum(String enrollmentId) async {
    try {
      isLoadingCurriculum.value = true;
      curriculumError.value = null;
      final data = await _courseRepository.getEnrollmentCurriculum(enrollmentId);
      curriculum.value = data;
    } catch (e) {
      print('fetchCurriculum error: $e');
      curriculum.value = null;
      curriculumError.value = e.toString();
    } finally {
      isLoadingCurriculum.value = false;
    }
  }

  var currentLessonProgress = Rxn<LessonProgress>();

  Future<LessonProgress?> startLesson({
    required String unitId,
    required String lessonId,
  }) async {
    try {
      final p = await _courseRepository.startLesson(unitId: unitId, lessonId: lessonId);
      currentLessonProgress.value = p;
      return p;
    } catch (e) {
      print('startLesson error: $e');
      return null;
    }
  }

  var popularCourses = <CoursePopular>[].obs;
  var isLoadingPopularCourses = false.obs;

  Future<void> fetchPopularCourses({int count = 10}) async {
    try {
      isLoadingPopularCourses.value = true;
      final list = await _courseRepository.getCoursePopular(count: count);
      popularCourses.assignAll(list);
    } catch (e) {
      popularCourses.clear();
      print('fetchPopularCourses error: $e');
    } finally {
      isLoadingPopularCourses.value = false;
    }
  }

  var isSubmittingExercise = false.obs;

  Future<String?> submitExercise({
    required String exerciseId,
    required String audioFilePath,
  }) async {
    try {
      isSubmittingExercise.value = true;
      // Gọi repository, nhận về exerciseSubmissionId
      return await _courseRepository.submitExercise(
        exerciseId: exerciseId,
        audioFilePath: audioFilePath,
      );
    } catch (e) {
      print('submitExercise error: $e');
      return null;
    } finally {
      isSubmittingExercise.value = false;
    }
  }

  var exerciseDetail = Rxn<Exercise>();
  var isLoadingExerciseDetail = false.obs;

  Future<Exercise?> fetchExerciseDetail(String exerciseId) async {
    try {
      isLoadingExerciseDetail.value = true;
      final ex = await _courseRepository.getExerciseDetail(exerciseId);
      exerciseDetail.value = ex;
      return ex;
    } catch (e) {
      exerciseDetail.value = null;
      return null;
    } finally {
      isLoadingExerciseDetail.value = false;
    }
  }

  var lastSubmissionDetail = Rxn<ExerciseSubmissionDetail>();


  Future<ExerciseSubmissionDetail?> fetchSubmissionDetail(String submissionId) async {
    try {
      return await _courseRepository.fetchSubmissionDetail(submissionId);
    } catch (e) {
      print('fetchSubmissionDetail error: $e');
      return null;
    }
  }

  final RxList<ExerciseSubmission> exerciseSubmissions = <ExerciseSubmission>[].obs;
  final RxBool isLoadingSubmissions = false.obs;

  Future<void> fetchExerciseSubmissions(String exerciseId, {int pageNumber = 1, int pageSize = 10}) async {
    isLoadingSubmissions.value = true;
    try {
      final submissions = await _courseRepository.getExerciseSubmissions(
        exerciseId: exerciseId,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      exerciseSubmissions.assignAll(submissions);
    } catch (e) {
      exerciseSubmissions.clear();
    } finally {
      isLoadingSubmissions.value = false;
    }
  }

  Future<Map<String, dynamic>?> enrollFreeCourse(String courseId) async {
    try {
      return await _courseRepository.enrollFreeCourse(courseId);
    } catch (e) {
      print('enrollFreeCourse error: $e');
      return null;
    }
  }
  Future<void> fetchPopularCoursesByLang({int count = 10, String? languageId}) async {
    try {
      isLoadingPopularCourses.value = true;
      final list = await _courseRepository.getCoursePopularByLang(count: count, languageId: languageId);
      popularCourses.assignAll(list);
    } catch (e) {
      popularCourses.clear();
      print('fetchPopularCourses error: $e');
    } finally {
      isLoadingPopularCourses.value = false;
    }
  }
}