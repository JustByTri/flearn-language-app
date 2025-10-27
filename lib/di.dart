import 'package:flearn_app/features/course/data/course_repository.dart';
import 'package:flearn_app/features/course/data/course_service.dart';
import 'package:flearn_app/features/course/viewmodel/course_viewmodel.dart';
import 'package:flearn_app/features/schedule/data/repository.dart';
import 'package:flearn_app/features/schedule/data/service.dart';
import 'package:flearn_app/features/survey/data/repository.dart';
import 'package:flearn_app/features/survey/data/service.dart';
import 'package:flearn_app/features/topic/data/repository.dart';
import 'package:flearn_app/core/services/dio_interceptor.dart'; 
import 'package:get/get.dart';
import 'package:dio/dio.dart';


import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_service.dart';
import 'features/topic/data/service.dart';


void setupDI() {
  Get.lazyPut<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://f-learn.app/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    dio.interceptors.add(DioInterceptor()); // Tự động thêm token vào mọi request
    return dio;
  }, fenix: true);
  Get.lazyPut<IAuthRepository>(() => AuthService(Get.find<Dio>()));
  Get.lazyPut<IRepository>(() => service());
  Get.lazyPut<ICourseRepository>(() => CourseService());
  Get.lazyPut<ISurveyRepository>(() => serviceSurvey());
  Get.lazyPut<IScheduleRepository>(() => ScheduleService());
  Get.lazyPut<CourseViewModel>(() => CourseViewModel(Get.find<ICourseRepository>()), fenix: true);

}
