class TeacherProfile {
  final String teacherId;
  final String userId;
  final String fullName;
  final String avatar;
  final String bio;
  final int totalCourses;
  final int totalStudents;
  final double averageRating;
  final int totalReviews;
  final List<PublishedCourse> publishedCourses;

  TeacherProfile({
    required this.teacherId,
    required this.userId,
    required this.fullName,
    required this.avatar,
    required this.bio,
    required this.totalCourses,
    required this.totalStudents,
    required this.averageRating,
    required this.totalReviews,
    required this.publishedCourses,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      teacherId: json['data']['teacherId'] ?? '',
      userId: json['data']['userId'] ?? '',
      fullName: json['data']['fullName'] ?? '',
      avatar: json['data']['avatar'] ?? '',
      bio: json['data']['bio'] ?? '',
      totalCourses: json['data']['totalCourses'] ?? 0,
      totalStudents: json['data']['totalStudents'] ?? 0,
      averageRating: (json['data']['averageRating'] ?? 0).toDouble(),
      totalReviews: json['data']['totalReviews'] ?? 0,
      publishedCourses: (json['data']['publishedCourses'] as List<dynamic>? ?? [])
          .map((e) => PublishedCourse.fromJson(e))
          .toList(),
    );
  }
}

class PublishedCourse {
  final String courseId;
  final String title;
  final String imageUrl;
  final double price;
  final double? discountPrice;
  final int learnerCount;
  final double averageRating;
  final int reviewCount;

  PublishedCourse({
    required this.courseId,
    required this.title,
    required this.imageUrl,
    required this.price,
    this.discountPrice,
    required this.learnerCount,
    required this.averageRating,
    required this.reviewCount,
  });

  factory PublishedCourse.fromJson(Map<String, dynamic> json) {
    return PublishedCourse(
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discountPrice'] != null ? (json['discountPrice']).toDouble() : null,
      learnerCount: json['learnerCount'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }
}
