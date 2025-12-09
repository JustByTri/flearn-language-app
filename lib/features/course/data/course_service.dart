import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../config/api_config.dart';
import '../../auth/model/course_popular.dart';
import '../model/all_exercise_submit.dart';
import '../model/course.dart';
import '../model/course_access.dart';
import '../model/course_detail.dart';
import '../model/course_exercise.dart';
import '../model/course_review.dart';
import '../model/course_unit.dart';
import '../model/course_lesson.dart';
import '../model/curriculum.dart';
import '../model/exercise_submission_detail.dart';
import '../model/lesson_progress_exercise.dart';
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
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Lỗi tải curriculum');
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
  Future<List<LessonProgressExercise>> getLessonProgressExercises(String lessonId) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/lesson-progress/lessons/$lessonId/exercises');  // Giả sử endpoint mới; thay nếu sai
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        if (accessToken != null && accessToken.toString().isNotEmpty)
          "Authorization": "Bearer $accessToken",
      },
    );
    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final data = jsonBody['data'] as List<dynamic>? ?? [];
      return data.map((item) => LessonProgressExercise.fromJson(item)).toList();
    } else {
      print('getLessonProgressExercises failed: ${response.statusCode} ${response.body}');
      return [];  // Trả rỗng để tránh crash
    }
  }
  @override
  Future<Exercise> getExerciseDetail(String exerciseId) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('${ApiConfig.baseUrl}/exercises/$exerciseId');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        if (accessToken != null && accessToken.toString().isNotEmpty)
          "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final data = jsonBody['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('getExerciseDetail: data null');
      }
      return Exercise.fromJson(data);
    }
    throw Exception('getExerciseDetail failed ${response.statusCode}: ${response.body}');
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
  Future<Map<String, dynamic>?> submitExercise({
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
    final file = File(audioFilePath);
    if (!await file.exists()) {
      return {'success': false, 'message': 'Audio file does not exist.'};
    }
    req.files.add(await http.MultipartFile.fromPath('Audio', audioFilePath, contentType: MediaType('audio', 'wav')));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final data = body['data'];
      final submissionId = data?['exerciseSubmissionId'] as String?;
      if (submissionId != null) {
        return {'success': true, 'submissionId': submissionId};
      } else {
        return {'success': false, 'message': 'Invalid response: missing submission ID.'};
      }
    } else {
      // Parse error from response body if available
      String errorMessage = 'Submission failed with status ${res.statusCode}.';
      try {
        final body = jsonDecode(res.body);
        if (body['message'] != null) {
          errorMessage = body['message'];
        } else if (body['error'] != null) {
          errorMessage = body['error'];
        }
      } catch (_) {
        // If parsing fails, keep default error
      }
      return {'success': false, 'message': errorMessage};
    }
  }

  @override
  Future<ExerciseSubmissionDetail?> fetchSubmissionDetail(String submissionId) async {
    final accessToken = GetStorage().read('accessToken');
    final detailUrl = Uri.parse(
        '${ApiConfig.baseUrl}/exercise-submission/submissions/$submissionId');
    final detailRes = await http.get(
      detailUrl,
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken
            .toString()
            .isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );
    print('fetchSubmissionDetail: ${detailRes.statusCode} ${detailRes.body}');
    if (detailRes.statusCode != 200) return null;

    try {
      final body = jsonDecode(detailRes.body);
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return ExerciseSubmissionDetail.fromJson(data);
    } catch (e) {
      print('parse ExerciseSubmissionDetail error: $e');
      return null;
    }
  }

  Future<List<ExerciseSubmission>> getExerciseSubmissions({
    required String exerciseId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse(
      'https://f-learn.app/api/exercise-submission/exercises/$exerciseId/submissions?pageNumber=$pageNumber&pageSize=$pageSize',
    );
    final response = await http.get(url, headers: {
      'accept': '*/*',
      if (accessToken != null && accessToken.toString().isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List data = body['data'] ?? [];
      return data.map((e) => ExerciseSubmission.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load submissions');
    }
  }


  @override
  Future<Map<String, dynamic>?> enrollFreeCourse(String courseId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/enrollments/free');
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
  Future<List<CoursePopular>> getCoursePopularByLang({int count = 10, String? languageId}) async {
    final accessToken = GetStorage().read('accessToken');
    final queryParams = {
      'count': '$count',
      if (languageId != null && languageId.isNotEmpty) 'languageId': languageId,
    };
    final url = Uri.parse('https://f-learn.app/api/courses/popular/by-language').replace(queryParameters: queryParams);
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
      print('getCoursePopularByLang: fetched ${data.length} courses for languageId=$languageId');
      print('response body: ${response.body}');
      return data.map((item) => CoursePopular.fromJson(item)).toList();


    } else {
      throw Exception('getCoursePopular failed: ${response.body}');
    }
  }

  @override
  Future<Map<String, dynamic>?> submitCourseReview({
    required String courseId,
    required int rating,
    required String comment,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/course-reviews/courses/$courseId');
    final token = GetStorage().read('accessToken');

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rating': rating, 'comment': comment}),
      );

      // Try parsing JSON if possible
      Map<String, dynamic> body = {};
      try { body = jsonDecode(res.body) as Map<String, dynamic>; } catch (_) {}

      // Case 3: backend returns only { "message": "..."} with 400
      if (body.isNotEmpty && body['message'] is String && body['status'] == null && body['code'] == null) {
        return {
          'status': 'fail',
          'code': res.statusCode,
          'message': body['message'],
          'duplicate': false,
          'data': null,
        };
      }

      // Normal success/fail envelope
      final status = (body['status'] ?? (res.statusCode >= 200 && res.statusCode < 300 ? 'success' : 'fail')).toString();
      final code = body['code'] is int ? body['code'] as int : res.statusCode;
      final message = (body['message'] ?? '').toString();
      final data = body['data'] as Map<String, dynamic>?;
      final errors = body['errors'] as Map<String, dynamic>?;
      final reviewJson = (data ?? errors);
      final review = reviewJson != null ? CourseReview.fromJson(reviewJson) : null;

      return {
        'status': status.toLowerCase(),
        'code': code,
        'message': message,
        'duplicate': code == 400 && (message.toLowerCase().contains('already reviewed')),
        'data': review,
      };
    } catch (e) {
      return {
        'status': 'fail',
        'code': 0,
        'message': e.toString(),
        'duplicate': false,
        'data': null,
      };
    }
  }

  @override
  Future<List<CourseReview>> getCourseReviews({
    required String courseId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final token = GetStorage().read('accessToken');
    final uri = Uri.parse('${ApiConfig.baseUrl}/course-reviews/courses/$courseId')
        .replace(queryParameters: {
      'page': '$page',
      'pageSize': '$pageSize',
    });

    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = (body['data'] as List?) ?? [];
      return data.map((e) => CourseReview.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('getCourseReviews failed: ${res.statusCode} ${res.body}');
  }

}