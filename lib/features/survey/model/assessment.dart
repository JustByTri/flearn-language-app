class Assessment {
  final String assessmentId;
  final String languageName;
  final String goalName;
  final int totalQuestions;
  final int currentQuestionIndex;
  final AssessmentQuestion firstQuestion;

  Assessment({
    required this.assessmentId,
    required this.languageName,
    required this.goalName,
    required this.totalQuestions,
    required this.currentQuestionIndex,
    required this.firstQuestion,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      assessmentId: json['assessmentId'],
      languageName: json['languageName'],
      goalName: json['goalName'],
      totalQuestions: json['totalQuestions'],
      currentQuestionIndex: json['currentQuestionIndex'],
      firstQuestion: AssessmentQuestion.fromJson(json['firstQuestion']),
    );
  }
}

class AssessmentQuestion {
  final int questionNumber;
  final String question;
  final String promptText;
  final String vietnameseTranslation;
  final List<WordGuide> wordGuides;
  final String questionType;
  final String difficulty;
  final int maxRecordingSeconds;
  final bool? isSkipped;
  final dynamic evaluationResult;
  final bool? canSkip;

  AssessmentQuestion({
    required this.questionNumber,
    required this.question,
    required this.promptText,
    required this.vietnameseTranslation,
    required this.wordGuides,
    required this.questionType,
    required this.difficulty,
    required this.maxRecordingSeconds,
    this.isSkipped,
    this.evaluationResult,
    this.canSkip
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestion(
      questionNumber: json['questionNumber'],
      question: json['question'],
      promptText: json['promptText'],
      vietnameseTranslation: json['vietnameseTranslation'],
      wordGuides: (json['wordGuides'] as List<dynamic>)
          .map((e) => WordGuide.fromJson(e))
          .toList(),
      questionType: json['questionType'],
      difficulty: json['difficulty'],
      maxRecordingSeconds: json['maxRecordingSeconds'],
      isSkipped: json['isSkipped'],
      evaluationResult: json['evaluationResult'],
      canSkip: json['canSkip'],
    );
  }
}

class WordGuide {
  final String word;
  final String pronunciation;
  final String vietnameseMeaning;
  final String example;

  WordGuide({
    required this.word,
    required this.pronunciation,
    required this.vietnameseMeaning,
    required this.example,
  });

  factory WordGuide.fromJson(Map<String, dynamic> json) {
    return WordGuide(
      word: json['word'],
      pronunciation: json['pronunciation'],
      vietnameseMeaning: json['vietnameseMeaning'],
      example: json['example'],
    );
  }
}