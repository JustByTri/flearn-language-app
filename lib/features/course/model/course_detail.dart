import 'course.dart';
import 'course_unit.dart';

class CourseDetail {
  final String courseId;

  final String language;
  final Program program;
  final Teacher teacher;
  final String title;
  final String description;
  final String learningOutcome;
  final String imageUrl;
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
  final String? publishedAt;
  final String? createdAt;
  final String? modifiedAt;
  final String? approvedBy;
  final String? approvedAt;
  final List<Topic> topics;
  final List<CourseUnit> units;

  CourseDetail({
    required this.courseId,
    required this.language,
    required this.program,
    required this.teacher,
    required this.title,
    required this.description,
    required this.learningOutcome,
    required this.imageUrl,
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
    this.publishedAt,
    this.createdAt,
    this.modifiedAt,
    this.approvedBy,
    this.approvedAt,
    required this.topics,
    required this.units,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return CourseDetail(
      courseId: json['courseId'],
      language: json['language'],
      program: Program.fromJson(json['program']),
      teacher: Teacher.fromJson(json['teacher']),
      title: json['title'],
      description: json['description'],
      learningOutcome: json['learningOutcome'] ?? '',
      imageUrl: json['imageUrl'],
      price: parseInt(json['price']),
      discountPrice: json['discountPrice'] != null ? parseInt(json['discountPrice']) : null,
      courseType: json['courseType'],
      gradingType: json['gradingType'],
      learnerCount: parseInt(json['learnerCount']),
      averageRating: parseDouble(json['averageRating']),
      reviewCount: parseInt(json['reviewCount']),
      numLessons: parseInt(json['numLessons']),
      numUnits: parseInt(json['numUnits']),
      durationDays: parseInt(json['durationDays']),
      estimatedHours: parseInt(json['estimatedHours']),
      courseStatus: json['courseStatus'],
      publishedAt: json['publishedAt'],
      createdAt: json['createdAt'],
      modifiedAt: json['modifiedAt'],
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'],
      topics: (json['topics'] as List<dynamic>? ?? []).map((e) => Topic.fromJson(e)).toList(),
      units: (json['units'] as List<dynamic>? ?? []).map((e) => CourseUnit.fromJson(e)).toList(),
    );
  }
}