class Course {
  final String courseID;
  final String title;
  final String description;
  final String imageUrl;
  final String? publishedAt;
  final String? status;
  final int price;
  final int? discountPrice;
  final String courseType;
  final String gradingType;
  final int learnerCount;
  final double averageRating;
  final int reviewCount;
  final int numLessons;
  final int numUnits;
  final int durationDays;
  final int estimatedHours;
  final String courseStatus;
  final String? createdAt;
  final String? modifiedAt;
  final String? approvedBy;
  final String? approvedAt;
  final String language;
  final Program? program;
  final Teacher? teacher;
  final List<Topic> topics;
  final List<dynamic> units;

  Course({
    required this.courseID,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.publishedAt,
    this.status,
    required this.price,
    this.discountPrice,
    required this.courseType,
    required this.gradingType,
    required this.learnerCount,
    required this.averageRating,
    required this.reviewCount,
    required this.numLessons,
    required this.numUnits,
    required this.durationDays,
    required this.estimatedHours,
    required this.courseStatus,
    this.createdAt,
    this.modifiedAt,
    this.approvedBy,
    this.approvedAt,
    required this.language,
    this.program,
    this.teacher,
    required this.topics,
    required this.units,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseID: json['courseId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      publishedAt: json['publishedAt'],
      status: json['status'],
      price: (json['price'] ?? 0) is num ? (json['price'] ?? 0).toInt() : 0,
      discountPrice: json['discountPrice'] is num ? json['discountPrice'] : null,
      courseType: json['courseType'] ?? '',
      gradingType: json['gradingType'] ?? '',
      learnerCount: json['learnerCount'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      numLessons: json['numLessons'] ?? 0,
      numUnits: json['numUnits'] ?? 0,
      durationDays: json['durationDays'] ?? 0,
      estimatedHours: json['estimatedHours'] ?? 0,
      courseStatus: json['courseStatus'] ?? '',
      createdAt: json['createdAt'],
      modifiedAt: json['modifiedAt'],
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'],
      language: json['language'] ?? '',
      program: json['program'] != null ? Program.fromJson(json['program']) : null,
      teacher: json['teacher'] != null ? Teacher.fromJson(json['teacher']) : null,
      topics: (json['topics'] as List<dynamic>? ?? [])
          .map((e) => Topic.fromJson(e))
          .toList(),
      units: json['units'] ?? [],
    );
  }
}

class Program {
  final String programId;
  final String name;
  final String description;
  final Level? level;

  Program({
    required this.programId,
    required this.name,
    required this.description,
    this.level,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      programId: json['programId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      level: json['level'] != null ? Level.fromJson(json['level']) : null,
    );
  }
}

class Level {
  final String levelId;
  final String name;
  final String description;

  Level({
    required this.levelId,
    required this.name,
    required this.description,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      levelId: json['levelId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class Teacher {
  final String teacherId;
  final String name;
  final String avatar;
  final String email;

  Teacher({
    required this.teacherId,
    required this.name,
    required this.avatar,
    required this.email,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      teacherId: json['teacherId'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class Topic {
  final String topicId;
  final String topicName;
  final String topicDescription;
  final String imageUrl;

  Topic({
    required this.topicId,
    required this.topicName,
    required this.topicDescription,
    required this.imageUrl,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      topicId: json['topicId'] ?? '',
      topicName: json['topicName'] ?? '',
      topicDescription: json['topicDescription'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
