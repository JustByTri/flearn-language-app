import 'package:get/get.dart';
import '../data/repository.dart';
import '../model/enrollment_model.dart';

class ScheduleViewModel extends GetxController {
  final IScheduleRepository service;

  ScheduleViewModel({required this.service});

  var isLoading = false.obs;
  var myEnrollments = <Enrollment>[].obs;
  var errorMessage = ''.obs;

  Future<void> fetchMyEnrollments() async {
    isLoading.value = true;
    try {
      final result = await service.getMyEnrollments();
      myEnrollments.value = result;
    } catch (e) {
      errorMessage.value = e.toString();
      myEnrollments.clear();
    } finally {
      isLoading.value = false;
    }
  }
}