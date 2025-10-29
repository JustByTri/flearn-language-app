import 'package:get/get.dart';
import '../../auth/data/auth_repository.dart';
import '../model/roadmap_detail.dart';

class RoadmapDetailViewModel extends GetxController {
  final IAuthRepository _authRepository;
  RoadmapDetailViewModel(this._authRepository);

  var isLoading = false.obs;
  var details = <RoadmapDetail>[].obs;
  var error = ''.obs;

  Future<void> fetchRoadmapDetails(String learnerLanguageId) async {
    try {
      isLoading.value = true;
      error.value = '';
      final resp = await _authRepository.fetchRoadmapDetails(learnerLanguageId);
      details.assignAll(resp.details);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}