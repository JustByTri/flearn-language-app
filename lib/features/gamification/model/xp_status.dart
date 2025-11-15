class XpStatus {
  final String learnerLanguageId;
  final String languageId;
  final int experiencePoints;
  final int todayXp;
  final int dailyXpGoal;
  final DateTime lastXpResetDate;
  final int streakDays;
  final int level;
  final double levelProgress;

  XpStatus({
    required this.learnerLanguageId,
    required this.languageId,
    required this.experiencePoints,
    required this.todayXp,
    required this.dailyXpGoal,
    required this.lastXpResetDate,
    required this.streakDays,
    required this.level,
    required this.levelProgress,
  });

  factory XpStatus.fromJson(Map<String, dynamic> json) {
    // Parse levelProgress safely
    double parsedLevelProgress = 0.0;
    final rawProgress = json['levelProgress'];
    if (rawProgress != null) {
      if (rawProgress is int) {
        parsedLevelProgress = rawProgress.toDouble();
      } else if (rawProgress is double) {
        parsedLevelProgress = rawProgress;
      } else {
        parsedLevelProgress = double.tryParse(rawProgress.toString()) ?? 0.0;
      }
    }

    return XpStatus(
      learnerLanguageId: json['learnerLanguageId'] ?? '',
      languageId: json['languageId'] ?? '',
      experiencePoints: json['experiencePoints'] ?? 0,
      todayXp: json['todayXp'] ?? 0,
      dailyXpGoal: json['dailyXpGoal'] ?? 50,
      lastXpResetDate: DateTime.parse(json['lastXpResetDate'] ?? DateTime.now().toIso8601String()),
      streakDays: json['streakDays'] ?? 0,
      level: json['level'] ?? 0,
      levelProgress: parsedLevelProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learnerLanguageId': learnerLanguageId,
      'languageId': languageId,
      'experiencePoints': experiencePoints,
      'todayXp': todayXp,
      'dailyXpGoal': dailyXpGoal,
      'lastXpResetDate': lastXpResetDate.toIso8601String(),
      'streakDays': streakDays,
      'level': level,
      'levelProgress': levelProgress,
    };
  }

  double get dailyProgress => dailyXpGoal > 0 ? (todayXp / dailyXpGoal).clamp(0.0, 1.0) : 0.0;
}

