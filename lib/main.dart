import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'app_binding.dart'; // Nhớ import file vừa tạo ở Bước 1
// Import các file cần thiết
import 'core/services/notification_service.dart';
import 'di.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_service.dart';
import 'shared/controllers/navigation_controller.dart';
import 'shared/widgets/authWrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  await GetStorage.init();
  await dotenv.load();

  setupDI();

  Get.put(NavigationController());
  Get.put<IAuthRepository>(AuthService(Dio()));
  await Firebase.initializeApp();
  final notificationService = Get.put(
    NotificationService(),
  );
  await notificationService.init();

  if (Platform.isAndroid) {

  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FLearn App',
      initialBinding: AppBinding(),

      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
