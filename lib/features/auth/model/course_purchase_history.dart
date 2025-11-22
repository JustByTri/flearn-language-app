class CoursePurchaseMeta {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  CoursePurchaseMeta({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory CoursePurchaseMeta.fromJson(Map<String, dynamic> json) {
    return CoursePurchaseMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class CoursePurchase {
  final String purchaseId;
  final String courseId;
  final String courseTitle;
  final String courseDescription;
  final String courseThumbnail;
  final String languageName;
  final String levelName;
  final int price;
  final int? discountPrice;
  final int finalAmount;
  final int discountAmount;
  final String status;
  final String paymentMethod;
  final String createdAt;
  final String? paidAt;
  final String? startsAt;
  final String? expiresAt;
  final String? eligibleForRefundUntil;
  final int daysRemaining;
  final bool isRefundEligible;
  final bool isActive;
  final String? enrollmentId;
  final String enrollmentStatus;
  final dynamic courseDetails;

  CoursePurchase({
    required this.purchaseId,
    required this.courseId,
    required this.courseTitle,
    required this.courseDescription,
    required this.courseThumbnail,
    required this.languageName,
    required this.levelName,
    required this.price,
    this.discountPrice,
    required this.finalAmount,
    required this.discountAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.paidAt,
    this.startsAt,
    this.expiresAt,
    this.eligibleForRefundUntil,
    required this.daysRemaining,
    required this.isRefundEligible,
    required this.isActive,
    this.enrollmentId,
    required this.enrollmentStatus,
    this.courseDetails,
  });

  factory CoursePurchase.fromJson(Map<String, dynamic> json) {
    return CoursePurchase(
      purchaseId: json['purchaseId'] ?? '',
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      courseDescription: json['courseDescription'] ?? '',
      courseThumbnail: json['courseThumbnail'] ?? '',
      languageName: json['languageName'] ?? '',
      levelName: json['levelName'] ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      discountPrice: json['discountPrice'] != null ? (json['discountPrice'] as num).toInt() : null,
      finalAmount: (json['finalAmount'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      createdAt: json['createdAt'] ?? '',
      paidAt: json['paidAt'],
      startsAt: json['startsAt'],
      expiresAt: json['expiresAt'],
      eligibleForRefundUntil: json['eligibleForRefundUntil'],
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
      isRefundEligible: json['isRefundEligible'] ?? false,
      isActive: json['isActive'] ?? false,
      enrollmentId: json['enrollmentId'],
      enrollmentStatus: json['enrollmentStatus'] ?? '',
      courseDetails: json['courseDetails'],
    );
  }
}