class CoursePurchaseDetail {
  final String purchaseId;
  final String courseId;
  final String courseName;
  final String courseDescription;
  final String courseThumbnail;
  final int coursePrice;
  final int? courseDiscountPrice;
  final int courseDurationDays;
  final String courseLevel;
  final String courseLanguage;
  final int totalAmount;
  final int discountAmount;
  final int finalAmount;
  final String purchaseStatus;
  final String paymentMethod;
  final String createdAt;
  final String? startsAt;
  final String? expiresAt;
  final String? eligibleForRefundUntil;
  final bool isRefundEligible;
  final int daysRemaining;
  final String enrollmentId;
  final String enrollmentStatus;

  CoursePurchaseDetail({
    required this.purchaseId,
    required this.courseId,
    required this.courseName,
    required this.courseDescription,
    required this.courseThumbnail,
    required this.coursePrice,
    this.courseDiscountPrice,
    required this.courseDurationDays,
    required this.courseLevel,
    required this.courseLanguage,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.purchaseStatus,
    required this.paymentMethod,
    required this.createdAt,
    this.startsAt,
    this.expiresAt,
    this.eligibleForRefundUntil,
    required this.isRefundEligible,
    required this.daysRemaining,
    required this.enrollmentId,
    required this.enrollmentStatus,
  });

  factory CoursePurchaseDetail.fromJson(Map<String, dynamic> json) {
    return CoursePurchaseDetail(
      purchaseId: json['purchaseId'] ?? '',
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? '',
      courseDescription: json['courseDescription'] ?? '',
      courseThumbnail: json['courseThumbnail'] ?? '',
      coursePrice: (json['coursePrice'] as num?)?.toInt() ?? 0,
      courseDiscountPrice: json['courseDiscountPrice'] != null ? (json['courseDiscountPrice'] as num).toInt() : null,
      courseDurationDays: (json['courseDurationDays'] as num?)?.toInt() ?? 0,
      courseLevel: json['courseLevel'] ?? '',
      courseLanguage: json['courseLanguage'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      finalAmount: (json['finalAmount'] as num?)?.toInt() ?? 0,
      purchaseStatus: json['purchaseStatus'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      createdAt: json['createdAt'] ?? '',
      startsAt: json['startsAt'],
      expiresAt: json['expiresAt'],
      eligibleForRefundUntil: json['eligibleForRefundUntil'],
      isRefundEligible: json['isRefundEligible'] ?? false,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
      enrollmentId: json['enrollmentId'] ?? '',
      enrollmentStatus: json['enrollmentStatus'] ?? '',
    );
  }
}