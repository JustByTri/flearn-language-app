import 'package:get/get.dart';
// Import các viewmodel của bạn
import 'features/auth/viewmodel/login_viewmodel.dart';
import 'features/auth/viewmodel/user_viewmodel.dart';
import 'features/course_progress/viewmodel/course_progress_viewmodel.dart';
import 'features/topic/viewmodel/topic_viewmodel.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Khởi tạo LoginViewModel (Vĩnh viễn)
    Get.put<LoginViewModel>(LoginViewModel(Get.find()), permanent: true);

    // Khởi tạo UserViewModel (Vĩnh viễn - vì dùng ở Header HomeScreen)
    Get.put<UserViewModel>(UserViewModel(Get.find()), permanent: true);

    // Khởi tạo TopicViewModel (Vĩnh viễn - vì dùng xuyên suốt)
    Get.put<TopicViewModel>(TopicViewModel(Get.find()), permanent: true);

    Get.put <CourseProgressViewModel>(CourseProgressViewModel(Get.find()),permanent: true);


  }}