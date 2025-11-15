import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/repository.dart';
import '../model/leaderboard_entry.dart';
import '../model/user_rank.dart';
import '../model/xp_status.dart';

class GamificationViewModel extends GetxController {
  final IGamificationRepository repository;

  GamificationViewModel({required this.repository});

  var isLoading = false.obs;
  var xpStatus = Rxn<XpStatus>();
  var userRank = Rxn<UserRank>();
  var weeklyLeaderboard = <LeaderboardEntry>[].obs;
  var monthlyLeaderboard = <LeaderboardEntry>[].obs;
  var errorMessage = ''.obs;
  var isLeaderboardWeekly = true.obs; // true = weekly, false = monthly

  @override
  void onInit() {
    super.onInit();
    fetchXpStatus();
    fetchLeaderboard();
  }

  String get selectedLanguageId {
    return GetStorage().read('selectedLanguageId') as String? ?? '00faa1ba-f715-431d-a9b2-2572729fccb2';
  }

  Future<void> fetchXpStatus() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final status = await repository.getMyXpStatus();
      xpStatus.value = status;

      // Also fetch user rank
      if (status.languageId.isNotEmpty) {
        final rank = await repository.getMyRank(status.languageId);
        userRank.value = rank;
      }
    } catch (e) {
      errorMessage.value = "Không thể tải thông tin XP. Vui lòng thử lại.";
      print('fetchXpStatus error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLeaderboard() async {
    try {
      final languageId = selectedLanguageId;
      if (isLeaderboardWeekly.value) {
        final entries = await repository.getWeeklyLeaderboard(languageId);
        weeklyLeaderboard.value = entries;
      } else {
        final entries = await repository.getMonthlyLeaderboard(languageId);
        monthlyLeaderboard.value = entries;
      }
    } catch (e) {
      errorMessage.value = "Không thể tải bảng xếp hạng. Vui lòng thử lại.";
      print('fetchLeaderboard error: $e');
    }
  }

  Future<void> updateDailyGoal(int newGoal) async {
    try {
      print('[GamificationViewModel] Updating daily goal to $newGoal');
      final success = await repository.updateDailyGoal(newGoal);
      print('[GamificationViewModel] Update result: $success');

      if (success) {
        // Reload XP status to get updated data
        await fetchXpStatus();
        Get.snackbar(
          'Thành công',
          'Đã cập nhật mục tiêu hàng ngày thành $newGoal XP!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể cập nhật mục tiêu. Vui lòng thử lại.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      print('[GamificationViewModel] updateDailyGoal error: $e');
      Get.snackbar(
        'Lỗi',
        'Đã xảy ra lỗi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  void toggleLeaderboardPeriod() {
    isLeaderboardWeekly.value = !isLeaderboardWeekly.value;
    fetchLeaderboard();
  }

  List<LeaderboardEntry> get currentLeaderboard {
    return isLeaderboardWeekly.value ? weeklyLeaderboard : monthlyLeaderboard;
  }

  String get currentUserId {
    final user = GetStorage().read('user') as Map?;
    return user?['userID']?.toString() ?? user?['id']?.toString() ?? '';
  }
}

