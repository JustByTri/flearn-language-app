import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../features/auth/data/auth_repository.dart';

class NotificationService extends GetxService {
  static final NotificationService instance =
      NotificationService._();
  factory NotificationService() => instance;
  NotificationService._();

  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin
  _localNotifications = FlutterLocalNotificationsPlugin();

  IAuthRepository get _authRepo {
    try {
      return Get.find<IAuthRepository>();
    } catch (e) {
      throw Exception("AuthRepository not found in GetX");
    }
  }

  Future<void> init() async {
    NotificationSettings settings = await _messaging
        .requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

    if (settings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings(
            '@mipmap/ic_launcher',
          );

      final DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestSoundPermission: false,
            requestBadgePermission: false,
            requestAlertPermission: false,
          );

      final InitializationSettings initSettings =
          InitializationSettings(
            android: androidSettings,
            iOS: iosSettings,
          );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) {
              // Xử lý khi bấm vào thông báo local (khi App đang mở)
              if (response.payload != null) {
                _handleMessageClick(response.payload!);
              }
            },
      );

      String? token = await _messaging.getToken();
      if (token != null) {
        print("📲 FCM Token: $token");
        syncTokenToServer(token);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        print("🔄 FCM Token Refreshed: $newToken");
        syncTokenToServer(newToken);
      });

      FirebaseMessaging.onMessage.listen((
        RemoteMessage message,
      ) {
        print(
          "📩 Received Foreground Message: ${message.notification?.title}",
        );

        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((
        RemoteMessage message,
      ) {
        print(
          "🚀 Notification Clicked (Background): ${message.data}",
        );
        _handleMessageClickFromRemote(message.data);
      });

      _messaging.getInitialMessage().then((
        RemoteMessage? message,
      ) {
        if (message != null) {
          print(
            "🚀 App Launched from Notification (Terminated): ${message.data}",
          );
          _handleMessageClickFromRemote(message.data);
        }
      });
    } else {
      print(
        '❌ User declined or has not accepted permission',
      );
    }
  }

  Future<void> syncTokenToServer(String token) async {
    final box = GetStorage();
    String? accessToken = box.read('accessToken');
    bool isLoggedIn =
        accessToken != null && accessToken.isNotEmpty;

    if (isLoggedIn) {
      try {
        await _authRepo.updateFcmToken(token);
        print("✅ Đã sync FCM token lên server thành công");
      } catch (e) {
        print(
          "⚠️ Sync token lỗi (có thể do mạng hoặc server): $e",
        );
      }
    } else {
      print(
        "ℹ️ User chưa login, không sync token lên server.",
      );
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android =
        message.notification?.android;

    if (notification != null && android != null) {
      String? submissionId = message.data['submissionId'];
      String? type = message.data['type'];
      String payload = submissionId ?? "";
      if (type != null) {
        payload = "$type|$submissionId";
      }

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_id_flearn',
            'Flearn Notifications',
            channelDescription:
                'Thông báo kết quả bài tập và nhắc nhở',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            // color: const Color(0xFF0066FF),
          ),
        ),
        payload: payload,
      );
    }
  }

  // Xử lý khi bấm thông báo (Data từ Firebase RemoteMessage)
  void _handleMessageClickFromRemote(
    Map<String, dynamic> data,
  ) {
    if (data['type'] == 'exercise_result') {
      String? submissionId = data['submissionId'];

      if (submissionId != null) {
        // Navigate đến màn hình kết quả
        // Thay '/exercise-result' bằng tên route thật trong AppPages của bạn
        // Ví dụ: Routes.SUBMISSION_DETAIL
        Get.toNamed(
          '/submission-detail',
          arguments: submissionId,
        );
      }
    }
  }

  // Xử lý khi bấm thông báo (Payload từ Local Notification)
  void _handleMessageClick(String payload) {
    if (payload.isEmpty) return;

    // Nếu payload format là "type|id"
    if (payload.contains("|")) {
      var parts = payload.split("|");
      var type = parts[0];
      var id = parts[1];

      if (type == 'exercise_result') {
        Get.toNamed('/submission-detail', arguments: id);
      }
    } else {
      // Trường hợp chỉ gửi mỗi ID (như code cũ) thì mặc định là exercise result
      Get.toNamed('/submission-detail', arguments: payload);
    }
  }
}
