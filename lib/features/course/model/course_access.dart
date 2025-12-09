class CourseAccess {
  final bool hasAccess;
  final String? expiresAt;
  final int daysRemaining;
  final String? refundEligibleUntil;
  final String accessStatus;
  final String? purchaseId;
  final String? enrollmentId;

  CourseAccess({
    required this.hasAccess,
    this.expiresAt,
    required this.daysRemaining,
    this.refundEligibleUntil,
    required this.accessStatus,
    this.purchaseId,
    this.enrollmentId,
  });

  factory CourseAccess.fromJson(Map<String, dynamic> json) {
    return CourseAccess(
      hasAccess: json['hasAccess'] ?? false,
      expiresAt: json['expiresAt'],
      daysRemaining: json['daysRemaining'] ?? 0,
      refundEligibleUntil: json['refundEligibleUntil'],
      accessStatus: json['accessStatus'] ?? '',
      purchaseId: json['purchaseId'],
      enrollmentId: json['enrollmentId'],
    );
  }
}