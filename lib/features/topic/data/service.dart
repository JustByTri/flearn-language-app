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

      _hubConnection?.on('AIMessageReceived', (args) {
        print('🔹 AIMessageReceived: $args');
        try {
          final dynamic raw = (args != null && args.isNotEmpty) ? args[0] : null;
          Map<String, dynamic> payload;
          if (raw is Map) {
            payload = raw.map((k, v) => MapEntry(k.toString(), v));
          } else if (raw is String) {
            payload = jsonDecode(raw) as Map<String, dynamic>;
          } else {
            print('[service] Unsupported payload: ${raw.runtimeType}');
            return;
          }
          onAiMessageReceived?.call(payload);
        } catch (e) {
          print('[service] on AIMessageReceived error: $e');
        }
      });

      // NEW: nhận voice (user vừa gửi) để UI hiển thị bong bóng voice
      _hubConnection?.on('VoiceMessageReceived', (args) {
        print('🔹 VoiceMessageReceived: $args');
        try {
          final dynamic raw = (args != null && args.isNotEmpty) ? args[0] : null;
          Map<String, dynamic> payload;
          if (raw is Map) {
            payload = raw.map((k, v) => MapEntry(k.toString(), v));
          } else if (raw is String) {
            payload = jsonDecode(raw) as Map<String, dynamic>;
          } else {
            print('[service] Unsupported payload: ${raw.runtimeType}');
            return;
          }
          onAiMessageReceived?.call(payload);
        } catch (e) {
          print('[service] on VoiceMessageReceived error: $e');
        }
      });

      // NEW: nhận lỗi từ hub
      _hubConnection?.on('Error', (args) {
        print('🔹 Hub Error: $args');
      });

      await _hubConnection?.start();
      print('SignalR connected');
    } catch (e) {
      print('SignalR connect error: $e');
    }
  }

  Future<void> disposeSignalR() async {
    // chỉ dừng hub, không liên quan stream của VM
    try { await _hubConnection?.stop(); } catch (_) {}
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
    if (transcript != null && transcript.trim().isNotEmpty && transcript != "string") {
      request.fields['transcript'] = transcript;
    }

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

  @override
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

  @override
  Future<void> joinConversationRoom(
      String sessionId,
      ) async {
    print('[SignalR] joinConversationRoom: sessionId=$sessionId');
    await _hubConnection?.invoke(
      "JoinConversationRoom",
      args: [sessionId],
    );
    print('[SignalR] Joined room: $sessionId');
  }

  @override
  Future<void> sendConversationMessageSignalR({
    required String sessionId,
    required String messageContent,
    required String messageType,
  }) async {
    print('[SignalR] sendConversationMessageSignalR: sessionId=$sessionId, messageContent=$messageContent, messageType=$messageType');
    await _hubConnection?.invoke(
      "SendMessageToConversation",
      args: [sessionId, messageContent, messageType],
    );
    print('[SignalR] Message sent via SignalR');
  }

  @override
  Future<void> sendVoiceMessageSignalR({
    required String sessionId,
    required String audioUrl,
    required int audioDuration,
  }) async {
    print('[SignalR] sendVoiceMessageSignalR: sessionId=$sessionId, audioUrl=$audioUrl, audioDuration=$audioDuration');
    await _hubConnection?.invoke(
      "SendVoiceMessage",
      args: [sessionId, audioUrl, audioDuration],
    );
    print('[SignalR] Voice message sent via SignalR');
  }

  // NEW: gửi voice base64 trực tiếp lên hub
  @override
  Future<void> sendVoiceMessageBase64SignalR({
    required String sessionId,
    required String base64Audio,
    required String mimeType,
    required int audioDuration,
  }) async {
    print('[SignalR] sendVoiceMessageBase64SignalR: sessionId=$sessionId, mimeType=$mimeType, duration=$audioDuration, base64Len=${base64Audio.length}');
    await _hubConnection?.invoke(
      "SendVoiceMessageToConversation",
      args: [sessionId, base64Audio, mimeType, audioDuration],
    );
    print('[SignalR] Voice(base64) sent via SignalR');
  }

  @override
  Future<Map<String, dynamic>?> fetchConversationUsage() async {
    final storage = GetStorage();
    final accessToken = storage.read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/conversation/usage');
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
        if (jsonBody['success'] == true && jsonBody['data'] != null) {
          return jsonBody['data'];
        }
      }
      return null;
    } catch (e) {
      print('fetchConversationUsage error: $e');
      return null;
    }
  }
}