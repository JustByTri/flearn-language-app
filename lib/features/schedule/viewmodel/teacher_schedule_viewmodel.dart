import 'package:get/get.dart';
import '../data/repository.dart';
import '../model/schedule_model.dart';

class TeacherScheduleViewModel extends GetxController {
  final IScheduleRepository service;
  TeacherScheduleViewModel({required this.service});

  var isLoading = false.obs;
  var schedules = <TeacherClass>[].obs;
  var errorMessage = ''.obs;

  Future<void> fetchSchedules({String? languageId}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await service.getTeacherSchedules(languageId: languageId);
      schedules.value = result;
    } catch (e) {
      errorMessage.value = e.toString();
      schedules.clear();
    } finally {
      isLoading.value = false;
    }
  }
  Future<Map<String, dynamic>> enrollClass(String classId) async {
    try {
      final result = await service.enroll(classId: classId);
      return result;
    } catch (e) {
      rethrow;
    }
  }
}