import 'dart:convert';
import 'dart:io';

import 'package:flearn_app/features/topic/data/repository.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:signalr_netcore/itransport.dart';

import '../../../config/api_config.dart';
import '../model/conversationLanguage.dart';
import '../model/topic.dart';

class service implements IRepository {
  HubConnection? _hubConnection;
  Function(Map<String, dynamic>)? onAiMessageReceived;

  Future<void> initSignalR() async {
    try {
      final accessToken = GetStorage().read('accessToken');
      if (accessToken == null || accessToken.isEmpty) {
        print(
          '❌ SignalR connect error: Access token is null or empty',
        );
        return;
      }
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) =>
        true;
      final options = HttpConnectionOptions(
        accessTokenFactory: () async => accessToken,
        transport: HttpTransportType.WebSockets,
        skipNegotiation: false,
      );

      _hubConnection = HubConnectionBuilder()
          .withUrl(
        "https://f-learn.app/conversationHub",
        options: options,
      )
          .withAutomaticReconnect()
          .build();

      _hubConnection?.on("AIMessageReceived", (args) {
        print("🔹 AIMessageReceived: $args");
        if (args != null &&
            args.isNotEmpty &&
            onAiMessageReceived != null) {
          try {
            final data = args[0];
            if (data is Map<String, dynamic>) {
              onAiMessageReceived!(data);
            } else if (data is String) {
              final parsed = jsonDecode(data);
              onAiMessageReceived!(parsed);
            }
          } catch (e) {
            print("⚠️ Error parsing AIMessageReceived: $e");
          }
        }
      });

      _hubConnection?.on("MessageProcessed", (args) {
        print("MessageProcessed: $args");
      });

      _hubConnection?.on("AIStartedTyping", (args) {
        print("AIStartedTyping: $args");
      });

      _hubConnection?.on("AIStoppedTyping", (args) {
        print("AIStoppedTyping: $args");
      });

      await _hubConnection?.start();
      print('SignalR connected');
    } catch (e) {
      print('SignalR connect error: $e');
    }
  }

  Future<void> disposeSignalR() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }

  @override
  Future<List<TopicModel>> getTopic() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.getTopic}',
    );
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
        final data =
            jsonBody['data'] as List<dynamic>? ?? [];
        return data
            .map((item) => TopicModel.fromJson(item))
            .toList();
      } else {
        print(
          'getTopic failed: ${response.statusCode} ${response.body}',
        );
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
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/conversation/start',
    );
    final body = {
      "languageId": languageId,
      "topicId": topicId,
      "difficultyLevel": difficultyLevel,
    };

    try {
      print('POST $url');
      print('BODY: $body');
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
      print(
        'RESPONSE: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return jsonBody['data'];
      }
      print(
        'startConversation failed: ${response.statusCode} ${response.body}',
      );
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
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/conversation/send-message',
    );
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
        print(
          'sendConversationMessage failed: ${response.statusCode} ${response.body}',
        );
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
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/conversation/send-voice',
    );
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] =
    'Bearer $accessToken';
    request.fields['sessionId'] = sessionId;
    request.fields['audioDuration'] = audioDuration
        .toString();
    if (transcript != null)
      request.fields['transcript'] = transcript;

    request.files.add(
      await http.MultipartFile.fromPath(
        'audioFile',
        audioFilePath,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return jsonBody;
    } else {
      print(
        'sendVoiceMessage failed: ${response.statusCode} ${response.body}',
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?>
  getConversationHistory() async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse(
      'https://f-learn.app/api/conversation/history',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          "accept": "/",
          "Authorization": "Bearer $accessToken",
        },
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return jsonBody;
      } else {
        print(
          'getConversationHistory failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('getConversationHistory error: $e');
      return null;
    }
  }

  @override
  Future<List<LanguageLevel>> getConversationLevels(String languageId) async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/languages/$languageId/levels');
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
        return data.map((item) => LanguageLevel.fromJson(item)).toList();
      } else {
        print('getConversationLevels failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('getConversationLevels error: $e');
      return [];
    }
  }

  Future<void> joinConversationRoom(
      String sessionId,
      ) async {
    await _hubConnection?.invoke(
      "JoinConversationRoom",
      args: [sessionId],
    );
    print('Joined SignalR room: $sessionId');
  }

  Future<void> sendConversationMessageSignalR({
    required String sessionId,
    required String messageContent,
    required int messageType,
    String? audioUrl,
    int? audioDuration,
    String? transcript,
  }) async {
    await _hubConnection?.invoke(
      "SendMessage",
      args: [
        sessionId,
        messageContent,
        messageType,
        audioUrl ?? "",
        audioDuration ?? 0,
        transcript ?? "",
      ],
    );
  }

  Future<void> sendVoiceMessageSignalR({
    required String sessionId,
    required String audioUrl,
    required int audioDuration,
    String? transcript,
  }) async {
    await _hubConnection?.invoke(
      "SendVoice",
      args: [
        sessionId,
        audioUrl,
        audioDuration,
        transcript ?? "",
      ],
    );
  }
}