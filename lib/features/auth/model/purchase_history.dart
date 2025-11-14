
int _asInt(dynamic v, {int defaultValue = 0}) {
  if (v == null) return defaultValue;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? defaultValue;
}

int? _asIntNullable(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  return s == 'true' || s == '1';
}

class PurchaseMeta {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  PurchaseMeta({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory PurchaseMeta.fromJson(Map<String, dynamic> json) {
    return PurchaseMeta(
      page: _asInt(json['page'], defaultValue: 1),
      pageSize: _asInt(json['pageSize'], defaultValue: 10),
      totalItems: _asInt(json['totalItems']),
      totalPages: _asInt(json['totalPages']),
    );
  }
}

class Purchase {
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
  final String? enrollmentId;
  final String enrollmentStatus;

  Purchase({
    required this.purchaseId,
    required this.courseId,
    required this.courseName,
    required this.courseDescription,
    required this.courseThumbnail,
    required this.coursePrice,
    required this.courseDiscountPrice,
    required this.courseDurationDays,
    required this.courseLevel,
    required this.courseLanguage,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.purchaseStatus,
    required this.paymentMethod,
    required this.createdAt,
    required this.startsAt,
    required this.expiresAt,
    required this.eligibleForRefundUntil,
    required this.isRefundEligible,
    required this.daysRemaining,
    required this.enrollmentId,
    required this.enrollmentStatus,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      purchaseId: json['purchaseId'] ?? '',
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? '',
      courseDescription: json['courseDescription'] ?? '',
      courseThumbnail: json['courseThumbnail'] ?? '',
      coursePrice: _asInt(json['coursePrice']),
      courseDiscountPrice: _asIntNullable(json['courseDiscountPrice']),
      courseDurationDays: _asInt(json['courseDurationDays']),
      courseLevel: json['courseLevel'] ?? '',
      courseLanguage: json['courseLanguage'] ?? '',
      totalAmount: _asInt(json['totalAmount']),
      discountAmount: _asInt(json['discountAmount']),
      finalAmount: _asInt(json['finalAmount']),
      purchaseStatus: json['purchaseStatus'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      createdAt: json['createdAt'] ?? '',
      startsAt: json['startsAt'],
      expiresAt: json['expiresAt'],
      eligibleForRefundUntil: json['eligibleForRefundUntil'],
      isRefundEligible: _asBool(json['isRefundEligible']),
      daysRemaining: _asInt(json['daysRemaining']),
      enrollmentId: json['enrollmentId'],
      enrollmentStatus: json['enrollmentStatus'] ?? '',
    );
  }
}