import 'package:flearn_app/features/course/data/course_repository.dart';
import 'package:flearn_app/features/course/data/course_service.dart';
import 'package:flearn_app/features/survey/data/repository.dart';
import 'package:flearn_app/features/survey/data/service.dart';
import 'package:flearn_app/features/topic/data/repository.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_service.dart';
import 'features/topic/data/service.dart';

final sl = GetIt.instance;

void setupDI() {

  Get.lazyPut<IAuthRepository>(() => AuthService());
  Get.lazyPut<IRepository>(() => service());
  Get.lazyPut<ICourseRepository>(() => CourseService());
  Get.lazyPut<ISurveyRepository>(() => serviceSurvey());
}
