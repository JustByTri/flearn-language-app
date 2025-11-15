import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../model/leaderboard_entry.dart';
import '../model/user_rank.dart';
import '../model/xp_status.dart';
import 'repository.dart';

class GamificationService implements IGamificationRepository {
  @override
  Future<XpStatus> getMyXpStatus() async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/gamification/me/status');

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      print('[GamificationService] getMyXpStatus status: ${response.statusCode}');
      print('[GamificationService] getMyXpStatus body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as Map<String, dynamic>;
        print('[GamificationService] XP data: $data');
        return XpStatus.fromJson(data);
      } else {
        throw Exception('Failed to load XP status: ${response.body}');
      }
    } catch (e) {
      print('[GamificationService] getMyXpStatus Exception: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateDailyGoal(int dailyXpGoal) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/gamification/me/daily-goal');

    try {
      print('[GamificationService] updateDailyGoal: Updating to $dailyXpGoal XP');
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "dailyXpGoal": dailyXpGoal,
        }),
      );

      print('[GamificationService] updateDailyGoal status: ${response.statusCode}');
      print('[GamificationService] updateDailyGoal body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return jsonBody['status'] == 'success' || jsonBody['success'] == true;
      } else {
        print('[GamificationService] updateDailyGoal failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[GamificationService] updateDailyGoal Exception: $e');
      return false;
    }
  }

  @override
  Future<UserRank> getMyRank(String languageId) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/gamification/leaderboard/$languageId/me');

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as Map<String, dynamic>;
        return UserRank.fromJson(data);
      } else {
        throw Exception('Failed to load user rank: ${response.body}');
      }
    } catch (e) {
      print('[GamificationService] getMyRank Exception: $e');
      rethrow;
    }
  }

  @override
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard(String languageId, {int count = 20}) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/gamification/leaderboard/$languageId/week?count=$count');

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => LeaderboardEntry.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load weekly leaderboard: ${response.body}');
      }
    } catch (e) {
      print('[GamificationService] getWeeklyLeaderboard Exception: $e');
      rethrow;
    }
  }

  @override
  Future<List<LeaderboardEntry>> getMonthlyLeaderboard(String languageId, {int count = 20}) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/gamification/leaderboard/$languageId/month?count=$count');

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((item) => LeaderboardEntry.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load monthly leaderboard: ${response.body}');
      }
    } catch (e) {
      print('[GamificationService] getMonthlyLeaderboard Exception: $e');
      rethrow;
    }
  }
}

