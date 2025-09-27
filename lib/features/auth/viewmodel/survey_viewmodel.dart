import 'package:get/get.dart';
import '../../auth/data/auth_repository.dart';
import "../model/survey_option.dart";
import '../model/survey_request.dart';

class SurveyViewModel extends GetxController {
  final IAuthRepository _authRepository;

  var isLoading = false.obs;
  var surveyOptions = Rxn<SurveyOptions>();

  SurveyViewModel(this._authRepository);

  Future<void> loadSurveyOptions() async {
    try {
      isLoading.value = true;
      print("Loading survey options...");

      final options = await _authRepository.getSurveyOptions();
      surveyOptions.value = options;

      if (options != null) {
        print("Survey options loaded successfully");
      } else {
        print("Failed to load survey options");
      }
    } catch (e) {
      print("Exception loading survey options: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> completeSurvey(SurveyRequest request) async {
    try {
      isLoading.value = true;
      print("Starting survey submission");

      final success = await _authRepository.completeSurvey(request);

      if (success) {
        print("Survey submitted successfully");
        return true;
      } else {
        print("Survey submission failed");
        return false;
      }
    } catch (e) {
      print("Survey submission exception: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }


}