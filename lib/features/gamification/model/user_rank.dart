class UserRank {
  final int rank;
  final int experiencePoints;
  final int streakDays;
  final int level;

  UserRank({
    required this.rank,
    required this.experiencePoints,
    required this.streakDays,
    required this.level,
  });

  factory UserRank.fromJson(Map<String, dynamic> json) {
    return UserRank(
      rank: json['rank'] ?? 0,
      experiencePoints: json['experiencePoints'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      level: json['level'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'experiencePoints': experiencePoints,
      'streakDays': streakDays,
      'level': level,
    };
  }
}

