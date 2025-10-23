import 'package:get/get.dart';

import '../data/repository.dart';
import '../model/assessment.dart';
import '../model/assessment_result.dart';
import '../model/goal.dart';

class SurveyViewModel extends GetxController {
  final ISurveyRepository _Repository;

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

  SurveyViewModel(this._Repository);

  Future<void> fetchLanguages() async {
    try {
      isLoadingLanguages.value = true;
      final map = await _Repository.getLanguages();
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
      final list = await _Repository.getGoals();
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
      final result = await _Repository.startAssessment(languageId, goalIds);
      if (result != null) {
        assessment.value = result;
        print("Assessment started: ${result.assessmentId}");
      } else {
        print("Failed to start assessment");
      }
    } catch (e) {
      print('startAssessment error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCurrentAssessmentQuestion(String assessmentId) async {
    try {
      isLoading.value = true;
      final question = await _Repository.getCurrentAssessmentQuestion(assessmentId);
      if (question != null) {
        currentQuestion.value = question;
        errorMessage.value = null;
        print("Fetched current assessment question: ${question.question}");
      } else {
        errorMessage.value = "Không thể tải câu hỏi";
        print("No current assessment question found");
      }
    } catch (e) {
      print('fetchCurrentAssessmentQuestion error: $e');
    } finally {
      isLoading.value = false;
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
      final result = await _Repository.submitVoiceAnswer(
        assessmentId: assessmentId,
        questionNumber: questionNumber,
        isSkipped: isSkipped,
        audioFilePath: audioFilePath,
        recordingDurationSeconds: recordingDurationSeconds,
      );
      if (result) {
        print("Voice answer submitted successfully");
      } else {
        print("Voice answer submission failed");
      }
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
      final result = await _Repository.completeAssessment(assessmentId);
      if (result != null) {
        print("Assessment completed: $result");
      } else {
        print("Failed to complete assessment");
      }
      return result;
    } catch (e) {
      print('completeAssessment error: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }


  Future<bool> acceptVoiceAssessment(String languageId) async {
    try {
      isLoading.value = true;
      final result = await _Repository.acceptVoiceAssessment(languageId);
      if (result) {
        print("Voice assessment accepted for languageId: $languageId");
      } else {
        print("Failed to accept voice assessment");
      }
      return result;
    } catch (e) {
      print('acceptVoiceAssessment error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> rejectVoiceAssessment(String languageId) async {
    try {
      isLoading.value = true;
      final result = await _Repository.rejectVoiceAssessment(languageId);
      if (result) {
        print("Voice assessment accepted for languageId: $languageId");
      } else {
        print("Failed to accept voice assessment");
      }
      return result;
    } catch (e) {
      print('acceptVoiceAssessment error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}