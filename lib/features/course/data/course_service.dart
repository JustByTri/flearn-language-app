import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../model/course.dart';
import '../model/course_access.dart';
import '../model/course_detail.dart';
import '../model/course_unit.dart';
import '../model/course_lesson.dart';
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
  }) async {
    final queryParams = {
      'Page': '$page',
      'PageSize': '$pageSize',
      if (status != null) 'status': status,
      if (searchTerm != null && searchTerm.isNotEmpty) 'SearchTerm': searchTerm,
      if (lang != null && lang.isNotEmpty) 'lang': lang,
    };
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getCourse}')
        .replace(queryParameters: queryParams);
    print('getCourse : $url');
    final res = await http.get(url, headers: {'Content-Type': 'application/json'});
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

  Future<bool> enrollCourse(String courseId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/enrollments');
    final accessToken = GetStorage().read('accessToken');
    final headers = {
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.toString().isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
    final body = jsonEncode({"courseId": courseId});
    final res = await http.post(url, headers: headers, body: body);
    if (res.statusCode == 200) {
      final jsonBody = jsonDecode(res.body);
      return jsonBody['success'] == true;
    }
    return false;
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

}