import 'dart:convert';
import 'dart:io';

import 'package:flearn_app/features/survey/data/repository.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../config/api_config.dart';
import '../model/assessment.dart';
import '../model/goal.dart';
import '../model/survey_option.dart';
import '../model/survey_request.dart';

class serviceSurvey implements ISurveyRepository {
  @override
  Future<SurveyOptions?> getSurveyOptions() async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.surveyOptionsUrl}');

    try {
      print("Getting survey options...");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      print("Survey options response status: ${response.statusCode}");
      print("Survey options response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SurveyOptions.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error["message"] ?? "Failed to get survey options");
      }
    } catch (e) {
      print("Survey options error: $e");
      return null;
    }
  }

  @override
  Future<bool> completeSurvey(SurveyRequest request) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.surveyCompleteUrl}');

    try {
      print("Survey request: ${jsonEncode(request.toJson())}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(request.toJson()),
      );

      print("Survey response status: ${response.statusCode}");
      print("Survey response body: ${response.body}");

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error["message"] ?? "Survey submission failed");
      }
    } catch (e) {
      print("Survey error: $e");
      throw Exception("Survey submission error: $e");
    }
  }


  @override
  Future<Map<String, String>> getLanguages() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getLanguages}');
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        final map = <String, String>{};
        for (final item in data) {
          final id = item['id']?.toString();
          final name = item['langName']?.toString();
          if (id != null && name != null) map[id] = name;
        }
        return map;
      } else {
        print('getLanguages failed: ${response.statusCode} ${response.body}');
        return {};
      }
    } catch (e) {
      print('getLanguages error: $e');
      return {};
    }
  }

  @override
  Future<List<Goal>> getGoals() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getGoal}');
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => Goal.fromJson(item)).toList();
      } else {
        print('getGoals failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('getGoals error: $e');
      return [];
    }
  }

  @override
  Future<Assessment?> startAssessment(String languageId, int goalId) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/VoiceAssessment/start/$languageId?goalId=$goalId');

    try {
      print("Starting assessment for languageId: $languageId, goalId: $goalId");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      print("Start assessment response status: ${response.statusCode}");
      print("Start assessment response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'];
        return Assessment.fromJson(data);
      } else {
        print('startAssessment failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('startAssessment error: $e');
      return null;
    }
  }

  @override
  Future<AssessmentQuestion?> getCurrentAssessmentQuestion(String assessmentId) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/VoiceAssessment/$assessmentId/current-question');

    try {
      print("Getting current assessment question for assessmentId: $assessmentId");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      print("Current question response status: ${response.statusCode}");
      print("Current question response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        if (jsonBody['success'] == true && jsonBody['data'] != null) {
          return AssessmentQuestion.fromJson(jsonBody['data']);
        }
        return null;
      } else {
        print('getCurrentAssessmentQuestion failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('getCurrentAssessmentQuestion error: $e');
      return null;
    }
  }

  @override
  Future<bool> submitVoiceAnswer({
    required String assessmentId,
    required int questionNumber,
    required bool isSkipped,
    String? audioFilePath,
    required int recordingDurationSeconds,
  }) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/VoiceAssessment/$assessmentId/submit-voice');

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $accessToken';

      request.fields['questionNumber'] = questionNumber.toString();
      request.fields['isSkipped'] = isSkipped.toString();
      request.fields['recordingDurationSeconds'] = recordingDurationSeconds.toString();

      if (audioFilePath != null && File(audioFilePath).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'audioFile',
            audioFilePath,
            contentType: MediaType('audio', 'wav'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("Submit voice answer status: ${response.statusCode}");
      print("Submit voice answer body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        print('submitVoiceAnswer failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('submitVoiceAnswer error: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> completeAssessment(String assessmentId) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/VoiceAssessment/$assessmentId/complete');

    try {
      print("Completing assessment for assessmentId: $assessmentId");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      print("Complete assessment response status: ${response.statusCode}");
      print("Complete assessment response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return jsonBody;
      } else {
        print('completeAssessment failed: ${response.statusCode} ${response
            .body}');
        return null;
      }
    } catch (e) {
      print('completeAssessment error: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> checkAssessmentStatus(String languageId, int goalId) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/VoiceAssessment/smart-start$languageId?goalId=$goalId');

    try {
      print(
          "Checking assessment status for languageId: $languageId, goalId: $goalId");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      print("Check assessment status response: ${response.statusCode}");
      print("Check assessment status body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return jsonBody;
      } else {
        print('checkAssessmentStatus failed: ${response.statusCode} ${response
            .body}');
        return null;
      }
    } catch (e) {
      print('checkAssessmentStatus error: $e');
      return null;
    }
  }


}