
import 'package:flearn_app/features/course/model/course.dart';

abstract class ICourseRepository{
  Future<List<Course>> getCourse();
}