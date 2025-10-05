import 'dart:convert';

import 'package:flearn_app/features/topic/data/repository.dart';
import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../model/topic.dart';

class service implements IRepository {
  @override
  Future<List<TopicModel>> getTopic() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getTopic}');
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => TopicModel.fromJson(item)).toList();
      } else {
        print('getLanguages failed: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('getLanguages error: $e');
      return [];
    }
  }
}