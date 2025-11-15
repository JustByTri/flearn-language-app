class LeaderboardEntry {
  final int rank;
  final String userId;
  final String userName;
  final String? avatar;
  final int xp;
  final int totalXp;
  final int streakDays;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.avatar,
    required this.xp,
    required this.totalXp,
    required this.streakDays,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      avatar: json['avatar'],
      xp: json['xp'] ?? 0,
      totalXp: json['totalXp'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'userName': userName,
      'avatar': avatar,
      'xp': xp,
      'totalXp': totalXp,
      'streakDays': streakDays,
    };
  }
}

