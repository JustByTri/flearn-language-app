
import '../model/assessment.dart';
import '../model/assessment_result.dart';
import '../model/goal.dart';


abstract class ISurveyRepository{

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

  Future<AssessmentResult?> completeAssessment(String assessmentId);

  Future<bool> acceptVoiceAssessment(String learnerLanguageId);

  Future<bool> rejectVoiceAssessment(String learnerLanguageId);


}