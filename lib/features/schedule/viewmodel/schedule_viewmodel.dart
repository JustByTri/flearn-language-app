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

  Future<Map<String, dynamic>?> submitRefundRequest({
    required String enrollmentID,
    required String classID,
    required String className,
    required int requestType,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountHolderName,
    required String reason,
  }) async {
    try {
      return await service.submitRefundRequest(
        enrollmentID: enrollmentID,
        classID: classID,
        className: className,
        requestType: requestType,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountHolderName: bankAccountHolderName,
        reason: reason,
      );
    } catch (e) {
      Get.snackbar('Lỗi', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return null;
    }
  }
}