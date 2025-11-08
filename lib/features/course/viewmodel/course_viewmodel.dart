import 'package:flearn_app/features/course/data/course_repository.dart';
import 'package:flearn_app/features/course/model/course.dart';
import 'package:get/get.dart';
import '../model/course_access.dart';
import '../model/course_detail.dart';
import '../model/course_lesson.dart';
import '../model/course_unit.dart';

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

  Future<bool> enrollCourse(String courseId) async {
    try {
      return await _courseRepository.enrollCourse(courseId);
    } catch (e) {
      print('CourseViewModel: enrollCourse error: $e');
      return false;
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
}