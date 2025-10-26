import 'package:get/get.dart';
import 'package:dio/dio.dart';

import '../data/repository.dart';
import '../model/assessment.dart';
import '../model/assessment_result.dart';
import '../model/goal.dart';

class SurveyViewModel extends GetxController {
  final ISurveyRepository _repository;

  var isLoading = false.obs;

  var isLoadingLanguages = false.obs;
  var languages = <String, String>{}.obs;
  String? selectedLanguageId;

  var goals = <Goal>[].obs;
  var isLoadingGoals = false.obs;

  var assessment = Rxn<Assessment>();

  var currentQuestion = Rxn<AssessmentQuestion>();
  var isLoadingCurrentQuestion = false.obs;

  var errorMessage = RxnString();

  SurveyViewModel(this._repository);

  Future<void> fetchLanguages() async {
    try {
      isLoadingLanguages.value = true;
      final map = await _repository.getLanguages();
      if (map.isNotEmpty) {
        languages.assignAll(map);
        selectedLanguageId ??= map.keys.first;
      }
    } catch (e) {
      print('fetchLanguages error: $e');
    } finally {
      isLoadingLanguages.value = false;
    }
  }

  Future<void> fetchGoals() async {
    try {
      isLoadingGoals.value = true;
      final list = await _repository.getGoals();
      if (list.isNotEmpty) {
        goals.assignAll(list);
      }
    } catch (e) {
      print('fetchGoals error: $e');
    } finally {
      isLoadingGoals.value = false;
    }
  }

  Future<void> startAssessment(String languageId, List<int> goalIds) async {
    try {
      isLoading.value = true;
      final result = await _repository.startAssessment(languageId, goalIds);
      if (result != null) {
        assessment.value = result;
        errorMessage.value = null; // Clear previous errors
        print("Assessment started: ${result.assessmentId}");
      } else {
        print("Failed to start assessment");
      }
    } on DioError catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Lỗi không xác định';
    } catch (e) {
      errorMessage.value = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      print('startAssessment error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCurrentAssessmentQuestion(String assessmentId) async {
    try {
      isLoadingCurrentQuestion.value = true;
      final question = await _repository.getCurrentAssessmentQuestion(assessmentId);
      currentQuestion.value = question;
      errorMessage.value = null; // Clear error on success
    } on DioError catch (e) {
      final responseMessage = e.response?.data?['message'] as String? ?? '';
      if (responseMessage.contains('Đã hoàn thành')) {
        errorMessage.value = 'ASSESSMENT_COMPLETED'; // Set special flag
      } else {
        errorMessage.value = responseMessage;
      }
      currentQuestion.value = null; 
      print('fetchCurrentAssessmentQuestion failed: ${e.response?.statusCode} $responseMessage');
    } catch (e) {
      errorMessage.value = 'Lỗi không xác định khi tải câu hỏi.';
      print('fetchCurrentAssessmentQuestion error: $e');
    } finally {
      isLoadingCurrentQuestion.value = false;
    }
  }

  Future<bool> submitVoiceAnswer({
    required String assessmentId,
    required int questionNumber,
    required bool isSkipped,
    String? audioFilePath,
    required int recordingDurationSeconds,
  }) async {
    try {
      isLoading.value = true;
      final result = await _repository.submitVoiceAnswer(
        assessmentId: assessmentId,
        questionNumber: questionNumber,
        isSkipped: isSkipped,
        audioFilePath: audioFilePath,
        recordingDurationSeconds: recordingDurationSeconds,
      );
      return result;
    } catch (e) {
      print('submitVoiceAnswer error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<AssessmentResult?> completeAssessment(String assessmentId) async {
    try {
      isLoading.value = true;
      final result = await _repository.completeAssessment(assessmentId);
      return result;
    } catch (e) {
      print('completeAssessment error: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // --- FIXED: Changed parameter and added function ---
  Future<bool> acceptVoiceAssessment(String learnerLanguageId) async {
    try {
      isLoading.value = true;
      final result = await _repository.acceptVoiceAssessment(learnerLanguageId);
      return result;
    } catch (e) {
      print('acceptVoiceAssessment error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> rejectVoiceAssessment(String learnerLanguageId) async {
    try {
      isLoading.value = true;
      final result = await _repository.rejectVoiceAssessment(learnerLanguageId);
      if (result) {
        print("Voice assessment rejected for learnerLanguageId: $learnerLanguageId");
      } else {
        print("Failed to reject voice assessment");
      }
      return result;
    } catch (e) {
      print('rejectVoiceAssessment error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
