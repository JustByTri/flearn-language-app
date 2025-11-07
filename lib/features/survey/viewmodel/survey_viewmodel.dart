import 'package:get/get.dart';
import 'package:dio/dio.dart';

import '../data/repository.dart';
import '../model/assessment.dart';
import '../model/assessment_result.dart';
import '../model/goal.dart';
import '../model/program.dart';

class SurveyViewModel extends GetxController {
  final ISurveyRepository _repository;

  var isLoading = false.obs;

  var isLoadingLanguages = false.obs;
  var languages = <String, String>{}.obs;
  String? selectedLanguageId;


  var programs = <Program>[].obs;
  var isLoadingPrograms = false.obs;

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


  Future<void> fetchPrograms(String languageId) async {
    try {
      isLoadingPrograms.value = true;
      final list = await _repository.getPrograms(languageId);
      programs.assignAll(list);
    } catch (e) {
      print('fetchPrograms error: $e');
      programs.clear();
    } finally {
      isLoadingPrograms.value = false;
    }
  }


  Future<void> startAssessment(String languageId, String programId) async {
    try {
      isLoading.value = true;
      final result = await _repository.startAssessment(languageId, programId);
      if (result != null) {
        assessment.value = result;
        errorMessage.value = null;
        print("Assessment started: ${result.assessmentId}");
      } else {
        print("Failed to start assessment");
      }
    } catch (e) {
      errorMessage.value = 'Lỗi không xác định khi bắt đầu đánh giá.';
      print('startAssessment error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCurrentAssessmentQuestion(String assessmentId) async {
    print('[SurveyViewModel] fetchCurrentAssessmentQuestion assessmentId: $assessmentId');
    try {
      isLoadingCurrentQuestion.value = true;
      final question = await _repository.getCurrentAssessmentQuestion(assessmentId);
      print('[SurveyViewModel] Question result: $question');
      currentQuestion.value = question;
      errorMessage.value = null;
    } catch (e) {
      print('[SurveyViewModel] Error: $e');
      errorMessage.value = 'ASSESSMENT_COMPLETED';
      currentQuestion.value = null;
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
