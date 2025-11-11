import 'package:get/get.dart';
import '../data/course_progress_repository.dart';
import '../model/course_progress.dart';

class CourseProgressViewModel extends GetxController {
  final ICourseProgressRepository _repository;
  var isLoading = false.obs;
  var courses = <CourseProgress>[].obs;

  CourseProgressViewModel(this._repository);

  Future<void> fetchMyCourses({int page = 1, int pageSize = 10}) async {
    try {
      isLoading.value = true;
      final list = await _repository.getMyCourses(page: page, pageSize: pageSize);
      courses.assignAll(list);
    } catch (e) {
      courses.clear();
      print('fetchMyCourses error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}