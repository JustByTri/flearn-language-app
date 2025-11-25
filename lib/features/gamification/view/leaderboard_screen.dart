import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:flutter/services.dart';
import '../viewmodel/gamification_viewmodel.dart';
import '../model/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final GamificationViewModel viewModel = Get.find<GamificationViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchLeaderboard();
      viewModel.fetchXpStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // Chữ trắng cho nền xanh
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Bảng xếp hạng',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SafeArea( // Đảm bảo không che status bar
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: Obx(() {
                  if (viewModel.isLoading.value) {
                    return const Center(
                      child: CupertinoActivityIndicator(radius: 15, color: Colors.blue),
                    );
                  }
                  final leaderboard = viewModel.currentLeaderboard;
                  if (leaderboard.isEmpty) {
                    return _buildEmptyState();
                  }
                  // Top 3 highlight
                  final top3 = leaderboard.take(3).toList();
                  final others = leaderboard.length > 3 ? leaderboard.sublist(3) : [];
                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: _buildTop3Section(top3),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                          ),
                          child: ListView(
                            padding: const EdgeInsets.only(top: 16, bottom: 80),
                            children: [
                              ...List.generate(others.length, (i) {
                                final entry = others[i];
                                final isCurrentUser = entry.userId == viewModel.currentUserId;
                                return _buildLeaderboardCard(entry, isCurrentUser, rank: i + 4);
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Obx(() {
      return Container(
        color: const Color(0xFF2196F3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(50),
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  'Tuần',
                  viewModel.isLeaderboardWeekly.value,
                      () {
                    if (!viewModel.isLeaderboardWeekly.value) {
                      viewModel.toggleLeaderboardPeriod();
                    }
                  },
                ),
              ),
              Expanded(
                child: _buildTabButton(
                  'Tháng',
                  !viewModel.isLeaderboardWeekly.value,
                      () {
                    if (viewModel.isLeaderboardWeekly.value) {
                      viewModel.toggleLeaderboardPeriod();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF2196F3) : Colors.white.withAlpha(180),
          ),
        ),
      ),
    );
  }

  Widget _buildTop3Section(List<LeaderboardEntry> top3) {
    Widget buildTopAvatar(LeaderboardEntry entry, int pos) {
      double size = pos == 1 ? 100 : 75;
      Color borderColor = pos == 1
          ? Color(0xFFFFD700) // Gold
          : (pos == 2 ? Color(0xFFC0C0C0) : Color(0xFFCD7F32)); // Silver/Bronze

      Widget avatar = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [borderColor, borderColor.withAlpha(200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withAlpha(100),
              blurRadius: 15,
              spreadRadius: 2,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(3),
          child: ClipOval(
            child: entry.avatar != null && entry.avatar!.isNotEmpty
                ? Image.network(entry.avatar!, fit: BoxFit.cover)
                : _buildDefaultAvatar(entry.userName, size: size - 14),
          ),
        ),
      );

      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (pos == 1)
            Positioned(
              top: -30,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFD700),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFFD700).withAlpha(150),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.emoji_events, color: Colors.white, size: 32),
              ),
            ),
          Positioned(
            bottom: 0,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: pos == 1
                      ? [Color(0xFFFFD700), Color(0xFFFFA500)]
                      : (pos == 2 ? [Color(0xFFC0C0C0), Color(0xFF808080)] : [Color(0xFFCD7F32), Color(0xFF8B4513)]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$pos',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1)
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  buildTopAvatar(top3[1], 2),
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          top3[1].userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars, color: Colors.amber, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Lv.${top3[1].streakDays}',
                              style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(230)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${top3[1].xp} XP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [
                buildTopAvatar(top3[0], 1),
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        top3[0].userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Lv.${top3[0].streakDays}',
                            style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(230)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFFD700).withAlpha(100),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${top3[0].xp} XP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (top3.length > 2)
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  buildTopAvatar(top3[2], 3),
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          top3[2].userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars, color: Colors.amber, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Lv.${top3[2].streakDays}',
                              style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(230)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${top3[2].xp} XP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, bool isCurrentUser, {int? rank}) {
    final displayRank = rank ?? entry.rank;
    final isTopRank = displayRank <= 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
      decoration: BoxDecoration(
        gradient: isCurrentUser
            ? LinearGradient(
          colors: [Color(0xFF2196F3).withAlpha(30), Color(0xFF42A5F5).withAlpha(30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isCurrentUser ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: Color(0xFF2196F3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isCurrentUser ? Color(0xFF2196F3).withAlpha(50) : Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: isTopRank
                    ? LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF2196F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: isTopRank ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$displayRank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isTopRank ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2196F3).withAlpha(40),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _buildAvatar(entry.avatar, entry.userName, size: 48),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isCurrentUser ? Color(0xFF2196F3) : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Bạn',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.stars, color: Colors.amber.shade700, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Lv.${entry.streakDays}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (entry.streakDays > 0) ...[
                        SizedBox(width: 8),
                        Icon(Icons.local_fire_department, color: Colors.orange.shade600, size: 14),
                        SizedBox(width: 2),
                        Text(
                          '${entry.streakDays}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4CAF50).withAlpha(60),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${entry.xp} XP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tổng tích lũy',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    IconData? icon;

    if (rank == 1) {
      badgeColor = Colors.amber.shade600;
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      badgeColor = Colors.grey.shade400;
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      badgeColor = Colors.brown.shade400;
      icon = Icons.emoji_events;
    } else {
      badgeColor = Colors.grey.shade300;
    }

    return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 20)
              : Text(
            '$rank',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ));
  }

  Widget _buildAvatar(String? avatarUrl, String userName, {double size = 50}) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Center(child: CupertinoActivityIndicator(radius: 10)),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(userName, size: size);
          },
        ),
      );
    }

    return _buildDefaultAvatar(userName, size: size);
  }

  Widget _buildDefaultAvatar(String userName, {double size = 50}) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(50),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size / 2.5,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text(
            'Chưa có dữ liệu xếp hạng',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy bắt đầu học tập để xuất hiện trên bảng xếp hạng!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
