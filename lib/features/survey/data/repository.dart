
import '../model/assessment.dart';
import '../model/goal.dart';
import '../model/survey_option.dart';
import '../model/survey_request.dart';
import '../model/survey_status.dart';

abstract class ISurveyRepository{
  Future<SurveyOptions?> getSurveyOptions();
  Future<bool> completeSurvey(SurveyRequest request);

  Future<Map<String, String>> getLanguages();

  Future<List<Goal>> getGoals();
  Future<Assessment?> startAssessment(String languageId, int goalId);

  Future<AssessmentQuestion?> getCurrentAssessmentQuestion(String assessmentId);

  Future<bool> submitVoiceAnswer({
    required String assessmentId,
    required int questionNumber,
    required bool isSkipped,
    String? audioFilePath,
    required int recordingDurationSeconds,
  });

  Future<Map<String, dynamic>?> completeAssessment(String assessmentId);
  Future<Map<String, dynamic>?> checkAssessmentStatus(String languageId, int goalId);
}