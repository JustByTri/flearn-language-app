import '../model/leaderboard_entry.dart';
import '../model/user_rank.dart';
import '../model/xp_status.dart';

abstract class IGamificationRepository {
  Future<XpStatus> getMyXpStatus();

  Future<bool> updateDailyGoal(int dailyXpGoal);

  Future<UserRank> getMyRank(String languageId);

  Future<List<LeaderboardEntry>> getWeeklyLeaderboard(String languageId, {int count = 20});

  Future<List<LeaderboardEntry>> getMonthlyLeaderboard(String languageId, {int count = 20});
}

