import 'package:flearn_app/features/course/data/course_repository.dart';
import 'package:flearn_app/features/course/model/course.dart';
import 'package:get/get.dart';
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
      final List<Course> list = await _courseRepository.getCourse(page: pageToFetch, pageSize: pageSize);
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
}