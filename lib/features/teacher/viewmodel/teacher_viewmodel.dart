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

  final isSubmittingReview = false.obs;

  Future<Map<String, dynamic>?> submitTeacherReview({
    required String teacherId,
    required int rating,
    required String comment,
  }) async {
    isSubmittingReview.value = true;
    try {
      return await _repository.submitTeacherReview(
        teacherId: teacherId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      return {
        'status': 'fail',
        'code': 0,
        'message': e.toString(),
      };
    } finally {
      isSubmittingReview.value = false;
    }
  }

  final RxList<Map<String, dynamic>> teacherReviews = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingReviews = false.obs;

  Future<void> fetchTeacherReviews(String teacherId, {int page = 1, int pageSize = 10}) async {
    isLoadingReviews.value = true;
    try {
      final reviews = await _repository.getTeacherReviews(
        teacherId: teacherId,
        page: page,
        pageSize: pageSize,
      );
      teacherReviews.assignAll(reviews);
    } catch (e) {
      teacherReviews.clear();
    } finally {
      isLoadingReviews.value = false;
    }
  }

}
