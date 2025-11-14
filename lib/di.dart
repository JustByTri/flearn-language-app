import 'package:flearn_app/features/course/data/course_repository.dart';
import 'package:flearn_app/features/course/data/course_service.dart';
import 'package:flearn_app/features/course/viewmodel/course_viewmodel.dart';
import 'package:flearn_app/features/schedule/data/repository.dart';
import 'package:flearn_app/features/schedule/data/service.dart';
import 'package:flearn_app/features/survey/data/repository.dart';
import 'package:flearn_app/features/survey/data/service.dart';
import 'package:flearn_app/features/teacher/data/teacher_repository.dart';
import 'package:flearn_app/features/teacher/data/teacher_service.dart';
import 'package:flearn_app/features/teacher/viewmodel/teacher_viewmodel.dart';
import 'package:flearn_app/features/topic/data/repository.dart';
import 'package:flearn_app/core/services/dio_interceptor.dart';
import 'package:flearn_app/shared/controllers/navigation_controller.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';


import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_service.dart';
import 'features/course_progress/data/course_progress_repository.dart';
import 'features/course_progress/data/course_progress_service.dart';
import 'features/survey/viewmodel/survey_viewmodel.dart';
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
  Get.lazyPut<IAuthRepository>(() => AuthService(Get.find<Dio>()), fenix: true);
  Get.lazyPut<IRepository>(() => service(), fenix: true);
  Get.lazyPut<ICourseRepository>(() => CourseService(), fenix: true);
  Get.lazyPut<ISurveyRepository>(() => serviceSurvey(), fenix: true);
  Get.lazyPut<IScheduleRepository>(() => ScheduleService(), fenix: true);
  Get.lazyPut<ITeacherRepository>(() => TeacherService(Get.find<Dio>()), fenix: true);
  Get.lazyPut<SurveyViewModel>(() => SurveyViewModel(Get.find<ISurveyRepository>()), fenix: true);
  Get.lazyPut<CourseViewModel>(() => CourseViewModel(Get.find<ICourseRepository>()), fenix: true);
  Get.lazyPut<TeacherViewModel>(() => TeacherViewModel(Get.find<ITeacherRepository>()), fenix: true);
  Get.lazyPut<ICourseProgressRepository>(() => CourseProgressService(), fenix: true);
  Get.lazyPut(() => NavigationController(), fenix: true);

}
