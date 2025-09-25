import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_service.dart';

final sl = GetIt.instance;

void setupDI() {
  // Register AuthService as implementation of IAuthRepository
  Get.lazyPut<IAuthRepository>(() => AuthService());
}
