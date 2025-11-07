import 'dart:convert';
import 'dart:io';

import 'package:flearn_app/features/survey/data/repository.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../config/api_config.dart';
import '../model/assessment.dart';
import '../model/assessment_result.dart';
import '../model/goal.dart';
import '../model/program.dart';


class serviceSurvey implements ISurveyRepository {

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
  Future<List<Program>> getPrograms(String languageId) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/VoiceAssessment/programs/$languageId');
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => Program.fromJson(item)).toList();
      } else {
        print('getPrograms failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('getPrograms error: $e');
      return [];
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
  Future<Assessment?> startAssessment(String languageId, String programId) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');

    final url = Uri.parse('${ApiConfig.baseUrl}/VoiceAssessment/start?languageId=$languageId&programId=$programId');

    try {
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

    print('[Service] accessToken: $accessToken');
    print('[Service] GET $url');

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    print("[Service] Response status: ${response.statusCode}");
    print("[Service] Response body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      if (jsonBody['success'] == true && jsonBody['data'] != null) {
        return AssessmentQuestion.fromJson(jsonBody['data']);
      }
      return null;
    } else {
      print('[Service] getCurrentAssessmentQuestion failed: ${response.statusCode} ${response.body}');
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
  Future<AssessmentResult?> completeAssessment(String assessmentId) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/VoiceAssessment/complete/$assessmentId');

    try {
      print('accessToken: $accessToken');
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
        if (jsonBody['success'] == true && jsonBody['data'] != null) {
          return AssessmentResult.fromJson(jsonBody['data']);
        }
      }
      return null;
    } catch (e) {
      print('completeAssessment error: $e');
      return null;
    }
  }


  @override
  Future<bool> acceptVoiceAssessment(String learnerLanguageId) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.acceptVoiceAssessment}');

    try {
      print("Accepting voice assessment for languageId: $learnerLanguageId");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({
          "learnerLanguageId": learnerLanguageId,
        }),
      );

      print("Accept voice assessment response status: ${response.statusCode}");
      print("Accept voice assessment response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return jsonBody['success'] == true;
      } else {
        print('acceptVoiceAssessment failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('acceptVoiceAssessment error: $e');
      return false;
    }
  }

  @override
  Future<bool> rejectVoiceAssessment(String learnerLanguageId) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.rejectVoiceAssessment}');

    try {
      print("Accepting voice assessment for languageId: $learnerLanguageId");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({
          "learnerLanguageId": learnerLanguageId,
        }),
      );

      print("Accept voice assessment response status: ${response.statusCode}");
      print("Accept voice assessment response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return jsonBody['success'] == true;
      } else {
        print('acceptVoiceAssessment failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('acceptVoiceAssessment error: $e');
      return false;
    }
  }



}