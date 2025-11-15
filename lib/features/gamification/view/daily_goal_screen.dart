import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import '../viewmodel/gamification_viewmodel.dart';

class DailyGoalScreen extends StatefulWidget {
  const DailyGoalScreen({super.key});

  @override
  State<DailyGoalScreen> createState() => _DailyGoalScreenState();
}

class _DailyGoalScreenState extends State<DailyGoalScreen> {
  final GamificationViewModel viewModel = Get.find<GamificationViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchXpStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF1A1A1A)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Mục tiêu học tập',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Obx(() {
        if (viewModel.isLoading.value) {
          return const Center(
            child: CupertinoActivityIndicator(radius: 15, color: AppColors.primary),
          );
        }

        final xpStatus = viewModel.xpStatus.value;
        if (xpStatus == null) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.fetchXpStatus(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDailyProgressCard(xpStatus),
                const SizedBox(height: 16),
                _buildStatsCard(xpStatus),
                const SizedBox(height: 16),
                _buildGoalSettingsCard(xpStatus),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDailyProgressCard(xpStatus) {
    final progress = xpStatus.dailyProgress;
    final todayXp = xpStatus.todayXp;
    final dailyGoal = xpStatus.dailyXpGoal;
    final isCompleted = todayXp >= dailyGoal;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mục tiêu hôm nay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Hoàn thành',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Circular progress
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        isCompleted ? Colors.green : AppColors.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$todayXp',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green : AppColors.primary,
                        ),
                      ),
                      Text(
                        'XP',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text(
              '$todayXp / $dailyGoal XP',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted
                  ? '🎉 Bạn đã hoàn thành mục tiêu hôm nay!'
                  : 'Còn ${dailyGoal - todayXp} XP nữa để đạt mục tiêu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(xpStatus) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.whatshot,
                    iconColor: Colors.orange,
                    label: 'Streak',
                    value: '${xpStatus.streakDays} ngày',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.stars,
                    iconColor: Colors.amber,
                    label: 'Tổng XP',
                    value: '${xpStatus.experiencePoints}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSettingsCard(xpStatus) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Điều chỉnh mục tiêu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            _buildGoalOption('Dễ dàng', 50, xpStatus.dailyXpGoal),
            const SizedBox(height: 8),
            _buildGoalOption('Vừa phải', 100, xpStatus.dailyXpGoal),
            const SizedBox(height: 8),
            _buildGoalOption('Thử thách', 200, xpStatus.dailyXpGoal),
            const SizedBox(height: 8),
            _buildGoalOption('Chuyên nghiệp', 500, xpStatus.dailyXpGoal),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalOption(String label, int xpValue, int currentGoal) {
    final isSelected = currentGoal == xpValue;

    return InkWell(
      onTap: () => _confirmUpdateGoal(xpValue),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF1A1A1A),
              ),
            ),
            Row(
              children: [
                Text(
                  '$xpValue XP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.primary : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text(
            'Không thể tải thông tin',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => viewModel.fetchXpStatus(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUpdateGoal(int newGoal) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cập nhật mục tiêu'),
        content: Text('Bạn muốn đặt mục tiêu hàng ngày là $newGoal XP?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Get.back(result: true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await viewModel.updateDailyGoal(newGoal);
    }
  }
}

