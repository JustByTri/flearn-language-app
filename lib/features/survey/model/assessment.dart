class Assessment {
  final String assessmentId;
  final String languageName;
  final String goalName;
  final int totalQuestions;

  Assessment({
    required this.assessmentId,
    required this.languageName,
    required this.goalName,
    required this.totalQuestions,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'];
    int totalQuestions = 0;
    if (questions != null && questions is List) {
      totalQuestions = questions.length;
    }
    return Assessment(
      assessmentId: json['assessmentId'] ?? '',
      languageName: json['languageName'] ?? '',
      goalName: json['goalName'] ?? '',
      totalQuestions: totalQuestions,
    );
  }
}

class AssessmentQuestion {
  final int questionNumber;
  final String question;
  final String promptText;
  final String? vietnameseTranslation;
  final List<WordGuide> wordGuides;
  final String questionType;
  final String difficulty;
  final int maxRecordingSeconds;
  final bool isSkipped;
  final String? audioFilePath;

  AssessmentQuestion({
    required this.questionNumber,
    required this.question,
    required this.promptText,
    this.vietnameseTranslation,
    required this.wordGuides,
    required this.questionType,
    required this.difficulty,
    required this.maxRecordingSeconds,
    required this.isSkipped,
    this.audioFilePath,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestion(
      questionNumber: json['questionNumber'] ?? 0,
      question: json['question'] ?? '',
      promptText: json['promptText'] ?? '',
      vietnameseTranslation: json['vietnameseTranslation'],
      wordGuides: (json['wordGuides'] as List<dynamic>? ?? [])
          .map((e) => WordGuide.fromJson(e))
          .toList(),
      questionType: json['questionType'] ?? '',
      difficulty: json['difficulty'] ?? '',
      maxRecordingSeconds: json['maxRecordingSeconds'] ?? 30,
      isSkipped: json['isSkipped'] ?? false,
      audioFilePath: json['audioFilePath'],
    );
  }
}

class WordGuide {
  final String word;
  final String pronunciation;
  final String vietnameseMeaning;
  final String? example;

  WordGuide({
    required this.word,
    required this.pronunciation,
    required this.vietnameseMeaning,
    this.example,
  });

  factory WordGuide.fromJson(Map<String, dynamic> json) {
    return WordGuide(
      word: json['word'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      vietnameseMeaning: json['vietnameseMeaning'] ?? '',
      example: json['example'],
    );
  }
}