class CourseReview {
  final String courseReviewId;
  final String learnerId;
  final String learnerName;
  final String? learnerAvatar;
  final String courseId;
  final String courseTitle;
  final int rating;
  final String comment;
  final String createdAt;
  final String? modifiedDate;

  CourseReview({
    required this.courseReviewId,
    required this.learnerId,
    required this.learnerName,
    required this.learnerAvatar,
    required this.courseId,
    required this.courseTitle,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.modifiedDate,
  });

  factory CourseReview.fromJson(Map<String, dynamic> json) {
    return CourseReview(
      courseReviewId: json['courseReviewId']?.toString() ?? '',
      learnerId: json['learnerId']?.toString() ?? '',
      learnerName: json['learnerName']?.toString() ?? '',
      learnerAvatar: json['learnerAvatar']?.toString(),
      courseId: json['courseId']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      rating: (json['rating'] is num) ? (json['rating'] as num).toInt() : int.tryParse('${json['rating']}') ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      modifiedDate: json['modifiedDate']?.toString(),
    );
  }

  Map<String, dynamic> toSubmitJson() => {
    'rating': rating,
    'comment': comment,
  };
}