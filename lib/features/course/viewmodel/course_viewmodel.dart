import 'package:flearn_app/features/course/data/course_repository.dart';
import 'package:flearn_app/features/course/model/course.dart';
import 'package:get/get.dart';
import '../model/course_lesson.dart';
import '../model/course_unit.dart';

class CourseViewModel extends GetxController {
  final ICourseRepository _courseRepository;

  var isLoadingCourse = false.obs;
  var courses = <Course>[].obs;

  // NEW: state cho paging theo nút
  final currentPage = 1.obs;
  final int pageSize = 4;
  final hasNextPage = false.obs;
  final hasPrevPage = false.obs;

  var isLoadingUnit = false.obs;
  var units = <CourseUnit>[].obs;

  var isLoadingLesson = false.obs;
  var lessons = <Lesson>[].obs;

  CourseViewModel(this._courseRepository);


  Future<void> fetchPage(int page) async {
    if (isLoadingCourse.value) return;
    try {
      isLoadingCourse.value = true;
      final list = await _courseRepository.getCourse(page: page, pageSize: pageSize);
      courses.assignAll(list);
      currentPage.value = page;
      hasPrevPage.value = page > 1;
      hasNextPage.value = list.length == pageSize;
      print('fetchPage($page): ${list.length} items');
    } catch (e) {
      print('fetchPage error: $e');
      courses.clear();
      hasNextPage.value = false;
      hasPrevPage.value = page > 1;
    } finally {
      isLoadingCourse.value = false;
    }
  }

  // Back-compat cho nơi khác đang gọi
  Future<void> fetchCourses({bool isRefresh = false}) {
    final page = isRefresh ? 1 : currentPage.value;
    return fetchPage(page);
  }

  Future<void> nextPage() async {
    if (!hasNextPage.value) return;
    await fetchPage(currentPage.value + 1);
  }

  Future<void> prevPage() async {
    if (!hasPrevPage.value) return;
    await fetchPage(currentPage.value - 1);
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