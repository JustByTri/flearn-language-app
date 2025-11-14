import 'package:get/get.dart';

import '../data/teacher_repository.dart';
import '../model/teacher_profile_model.dart';

class TeacherViewModel extends GetxController {
  final ITeacherRepository _repository;

  TeacherViewModel(this._repository);

  final Rx<TeacherProfile?> teacherProfile = Rx<TeacherProfile?>(null);
  final RxBool isLoading = false.obs;

  Future<void> fetchTeacherProfile(String teacherId) async {
    try {
      isLoading.value = true;
      final profile = await _repository.getTeacherProfile(teacherId);
      teacherProfile.value = profile;
    } catch (e) {
      // Handle error
      Get.snackbar('Error', 'Failed to load teacher profile.');
    } finally {
      isLoading.value = false;
    }
  }
}
