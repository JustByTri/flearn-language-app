
import 'package:flearn_app/features/auth/view/home_screen.dart';
import 'package:flearn_app/features/auth/view/profile_screen.dart';
import 'package:flearn_app/features/course/view/course_screen.dart';
import 'package:flearn_app/features/schedule/view/schedule_screen.dart';
import 'package:flearn_app/features/topic/view/topic_screen.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const HomeScreen(),
    const TopicScreen(),
    const CourseScreen(),
    const TeacherScheduleListScreen(),
    const ProfileScreen(),
  ];
}