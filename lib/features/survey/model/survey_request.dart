class SurveyRequest {
  final String currentLevel;
  final String preferredLanguageID;
  final String learningReason;
  final String previousExperience;
  final String preferredLearningStyle;
  final String interestedTopics;
  final String prioritySkills;
  final String targetTimeline;
  final String speakingChallenges;
  final int confidenceLevel;
  final String preferredAccent;

  SurveyRequest({
    required this.currentLevel,
    required this.preferredLanguageID,
    required this.learningReason,
    required this.previousExperience,
    required this.preferredLearningStyle,
    required this.interestedTopics,
    required this.prioritySkills,
    required this.targetTimeline,
    required this.speakingChallenges,
    required this.confidenceLevel,
    required this.preferredAccent,
  });

  Map<String, dynamic> toJson() => {
    'currentLevel': currentLevel,
    'preferredLanguageID': preferredLanguageID,
    'learningReason': learningReason,
    'previousExperience': previousExperience,
    'preferredLearningStyle': preferredLearningStyle,
    'interestedTopics': interestedTopics,
    'prioritySkills': prioritySkills,
    'targetTimeline': targetTimeline,
    'speakingChallenges': speakingChallenges,
    'confidenceLevel': confidenceLevel,
    'preferredAccent': preferredAccent,
  };
}