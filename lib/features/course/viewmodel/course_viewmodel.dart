import 'package:flearn_app/features/course/data/course_repository.dart';
import 'package:flearn_app/features/course/model/course.dart';
import 'package:get/get.dart';




class CourseViewModel extends GetxController {
  final ICourseRepository _courseRepository;
  var isLoadingCourse = false.obs;
  var courses = <Course>[].obs;

  CourseViewModel(this._courseRepository);

  Future<void> fetchCourses() async {
    try {
      isLoadingCourse.value = true;
      final list = await _courseRepository.getCourse();
      courses.assignAll(list);
    } catch (e) {
      print('fetchTopics error: $e');
    } finally {
      isLoadingCourse.value = false;
    }
  }
}