import 'package:get/get.dart';

import '../data/repository.dart';
import '../model/assessment.dart';
import '../model/goal.dart';
import "../model/survey_option.dart";
import '../model/survey_request.dart';

class SurveyViewModel extends GetxController {
  final ISurveyRepository _Repository;

  var isLoading = false.obs;
  var surveyOptions = Rxn<SurveyOptions>();

  var isLoadingLanguages = false.obs;
  var languages = <String, String>{}.obs;
  String? selectedLanguageId;

  var goals = <Goal>[].obs;
  var isLoadingGoals = false.obs;

  var assessment = Rxn<Assessment>();

  var currentQuestion = Rxn<AssessmentQuestion>();
  var isLoadingCurrentQuestion = false.obs;

  SurveyViewModel(this._Repository);

  Future<void> loadSurveyOptions() async {
    try {
      isLoading.value = true;
      print("Loading survey options...");

      final options = await _Repository.getSurveyOptions();
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

      final success = await _Repository.completeSurvey(request);

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

  Future<void> startAssessment(String languageId, int goalId) async {
    try {
      isLoading.value = true;
      final result = await _Repository.startAssessment(languageId, goalId);
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
        print("Fetched current assessment question: ${question.question}");
      } else {
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


  Future<Map<String, dynamic>?> completeAssessment(String assessmentId) async {
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


  Future<Map<String, dynamic>?> checkAssessmentStatus(String languageId, int goalId) async {
    try {
      isLoading.value = true;
      final result = await _Repository.checkAssessmentStatus(languageId, goalId);
      if (result != null) {
        print("Assessment status: $result");
      } else {
        print("Failed to check assessment status");
      }
      return result;
    } catch (e) {
      print('checkAssessmentStatus error: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

}