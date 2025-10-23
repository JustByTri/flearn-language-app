import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:flearn_app/features/topic/data/repository.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../config/api_config.dart';
import '../model/topic.dart';

class service implements IRepository {
  @override
  Future<List<TopicModel>> getTopic() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getTopic}');
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
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
        return data.map((item) => TopicModel.fromJson(item)).toList();
      } else {
        print('getTopic failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('getTopic error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> startConversation({
    required String languageId,
    required String topicId,
    required String difficultyLevel,
  }) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/conversation/start');
    final body = {
      "languageId": languageId,
      "topicId": topicId,
      "difficultyLevel": difficultyLevel,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        if (jsonBody['success'] == true) {
          return jsonBody['data'];
        }
      }
      print('startConversation failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('startConversation error: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> sendConversationMessage({
    required String sessionId,
    required String messageContent,
    required int messageType,
    String? audioUrl,
    String? audioPublicId,
    int? audioDuration,
  }) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/conversation/send-message');
    final body = {
      "sessionId": sessionId,
      "messageContent": messageContent,
      "messageType": messageType,
      "audioUrl": audioUrl ?? "",
      "audioPublicId": audioPublicId ?? "",
      "audioDuration": audioDuration ?? 0,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return jsonBody;
      } else {
        print('sendConversationMessage failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('sendConversationMessage error: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> sendVoiceMessage({
    required String sessionId,
    required String audioFilePath,
    required int audioDuration,
    String? transcript,
  }) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/conversation/send-voice');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $accessToken';
    request.fields['sessionId'] = sessionId;
    request.fields['audioDuration'] = audioDuration.toString();
    if (transcript != null) request.fields['transcript'] = transcript;

    request.files.add(
      await http.MultipartFile.fromPath(
        'audioFile',
        audioFilePath,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return jsonBody;
    } else {
      print('sendVoiceMessage failed: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getConversationHistory() async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/conversation/history');
    try {
      final response = await http.get(
        url,
        headers: {
          "accept": "*/*",
          "Authorization": "Bearer $accessToken",
        },
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return jsonBody;
      } else {
        print('getConversationHistory failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('getConversationHistory error: $e');
      return null;
    }
  }


}