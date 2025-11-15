import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../config/api_config.dart';
import '../../auth/model/course_popular.dart';
import '../model/course.dart';
import '../model/course_access.dart';
import '../model/course_detail.dart';
import '../model/course_exercise.dart';
import '../model/course_unit.dart';
import '../model/course_lesson.dart';
import '../model/curriculum.dart';
import '../model/lesson_tracking.dart';
import 'course_repository.dart';
import 'package:get_storage/get_storage.dart';

class CourseService implements ICourseRepository {
  @override
  @override
  Future<List<Course>> getCourse({
    int page = 1,
    int pageSize = 4,
    String? status,
    String? searchTerm,
    String? lang,
    String? sortBy,
  }) async {
    final queryParams = {
      'Page': '$page',
      'PageSize': '$pageSize',
      if (status != null) 'status': status,
      if (searchTerm != null && searchTerm.isNotEmpty) 'SearchTerm': searchTerm,
      if (lang != null && lang.isNotEmpty) 'lang': lang,
      if (sortBy != null && sortBy.isNotEmpty) 'SortBy': sortBy,
    };
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getCourse}')
        .replace(queryParameters: queryParams);
    print('getCourse : $url');
    final res = await http.get(url, headers: {'Content-Type': 'application/json'});

    // Handle 404 as empty list instead of throwing error
    if (res.statusCode == 404) {
      print('getCourse: No courses found for this language/filter');
      return [];
    }

    if (res.statusCode != 200) {
      throw Exception('getCourse failed ${res.statusCode}: ${res.body}');
    }
    final jsonBody = jsonDecode(res.body);
    final list = (jsonBody['data'] as List?) ?? <dynamic>[];
    return list.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<CourseUnit>> getCourseUnit(String courseId, {int page = 1, int pageSize = 10}) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/courses/$courseId/units?Page=$page&PageSize=$pageSize',
    );
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => CourseUnit.fromJson(item)).toList();
      } else {
        print('getCourseUnit failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('getCourseUnit error: $e');
      return [];
    }
  }

  @override
  Future<List<Lesson>> getCourseLessons(String courseUnitID, {int page = 1, int pageSize = 10}) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/units/$courseUnitID/lessons?page=$page&pageSize=$pageSize',
    );
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => Lesson.fromJson(item)).toList();
      } else {
        print('getCourseLessons failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('getCourseLessons error: $e');
      return [];
    }
  }


  @override
  Future<Map<String, dynamic>> createPurchase({
    required String courseId,
    int paymentMethod = 1,
    String? promotionCode,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/purchases');
    final accessToken = GetStorage().read('accessToken');
    final headers = {
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.toString().isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final body = {
      "courseId": courseId,
      "paymentMethod": paymentMethod,
      "promotionCode": promotionCode ?? "",
    };

    final res = await http.post(url, headers: headers, body: jsonEncode(body));
    if (res.statusCode != 200) {
      throw Exception('Create purchase failed: ${res.body}');
    }
    final jsonBody = jsonDecode(res.body);
    return jsonBody['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> payPurchase(String purchaseId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/purchases/$purchaseId/payments');
    final accessToken = GetStorage().read('accessToken');
    final headers = {
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.toString().isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final res = await http.post(url, headers: headers, body: '');
    if (res.statusCode != 200) {
      throw Exception('Pay purchase failed: ${res.body}');
    }
    final jsonBody = jsonDecode(res.body);
    return jsonBody['data'] as Map<String, dynamic>;
  }

  @override
  Future<CourseDetail> getCourseDetail(String courseId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/courses/$courseId/details');
    final res = await http.get(url, headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('getCourseDetail failed ${res.statusCode}: ${res.body}');
    }
    final jsonBody = jsonDecode(res.body);
    return CourseDetail.fromJson(jsonBody['data']);
  }
  @override
  Future<Map<String, dynamic>?> enrollCourse(String courseId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/enrollments');
    final accessToken = GetStorage().read('accessToken');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.toString().isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({"courseId": courseId}),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  @override
  Future<Curriculum> getEnrollmentCurriculum(String enrollmentId) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/enrollments/$enrollmentId/curriculums');
    final res = await http.get(url, headers: {
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.toString().isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    });
    if (res.statusCode != 200) {
      throw Exception('getEnrollmentCurriculum failed ${res.statusCode}: ${res.body}');
    }
    final jsonBody = jsonDecode(res.body);
    return Curriculum.fromJson(jsonBody['data']);
  }

  @override
  Future<LessonProgress> startLesson({
    required String unitId,
    required String lessonId,
  }) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/progress-tracking/start-lesson');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.toString().isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        "unitId": unitId,
        "lessonId": lessonId,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('startLesson failed ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body);
    return LessonProgress.fromJson(body['data']);
  }

  Future<CourseAccess> getCourseAccess(String courseId) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/enrollments/courses/$courseId/access');
    final res = await http.get(url, headers: {
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.toString().isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    });
    if (res.statusCode != 200) {
      throw Exception('getCourseAccess failed ${res.statusCode}: ${res.body}');
    }
    final jsonBody = jsonDecode(res.body);
    return CourseAccess.fromJson(jsonBody['data']);
  }

  @override
  Future<Lesson> getLessonById(String lessonId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/lessons/$lessonId');
    final response = await http.get(url, headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return Lesson.fromJson(jsonBody['data']);
    } else {
      throw Exception('getLessonById failed: ${response.body}');
    }
  }

  @override
  Future<List<Exercise>> getLessonExercises(String lessonId, {int page = 1, int pageSize = 10}) async {
    final url = Uri.parse('https://f-learn.app/api/lessons/$lessonId/exercises?Page=$page&PageSize=$pageSize');
    final response = await http.get(url, headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final data = jsonBody['data'] as List<dynamic>? ?? [];
      return data.map((item) => Exercise.fromJson(item)).toList();
    } else {
      return [];
    }
  }

  @override
  Future<void> trackLessonActivity({
    required String lessonId,
    required int logType,
    required int durationMinutes,
    required String metadata,
  }) async {
    final accessToken = GetStorage().read('accessToken');
    final dio = Dio();
    final response = await dio.post(
      'https://f-learn.app/api/progress-tracking/track-activity',
      data: {
        "lessonId": lessonId,
        "logType": logType,
        "durationMinutes": durationMinutes,
        "metadata": metadata,
      },
      options: Options(
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Track activity failed: ${response.data}');
    }
  }

  @override
  Future<List<CoursePopular>> getCoursePopular({int count = 10}) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/courses/popular?count=$count');
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
      return data.map((item) => CoursePopular.fromJson(item)).toList();
    } else {
      throw Exception('getCoursePopular failed: ${response.body}');
    }
  }

  @override
  Future<bool> submitExercise({
    required String exerciseId,
    required String audioFilePath,
  }) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/progress-tracking/submit-exercise');

    final req = http.MultipartRequest('POST', url);
    if (accessToken != null && accessToken.toString().isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $accessToken';
    }


    req.fields['ExerciseId'] = exerciseId;
    if (audioFilePath.isNotEmpty) {
      req.files.add(await http.MultipartFile.fromPath(
        'Audio',
        audioFilePath,
        contentType: MediaType('audio', 'wav'),
      ));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    print('submitExercise response: ${res.statusCode} ${res.body}');
    if (res.statusCode == 200) {
      return true;
    } else {
      print('submitExercise failed: ${res.statusCode} ${res.body}');
      return false;
    }
  }

}