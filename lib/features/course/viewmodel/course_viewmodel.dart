import 'package:flearn_app/features/course/data/course_repository.dart';
import 'package:flearn_app/features/course/model/course.dart';
import 'package:get/get.dart';

import '../model/course_lesson.dart';
import '../model/course_unit.dart';




class CourseViewModel extends GetxController {
  final ICourseRepository _courseRepository;
  var isLoadingCourse = false.obs;
  var courses = <Course>[].obs;

  var isLoadingUnit = false.obs;
  var units = <CourseUnit>[].obs;

  var isLoadingLesson = false.obs;
  var lessons = <Lesson>[].obs;

  CourseViewModel(this._courseRepository);

  Future<void> fetchCourses() async {
    try {
      isLoadingCourse.value = true;
      final list = await _courseRepository.getCourse();
      courses.assignAll(list);
      print('fetchCourses: fetched ${list.length} courses');

    } finally {
      isLoadingCourse.value = false;
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