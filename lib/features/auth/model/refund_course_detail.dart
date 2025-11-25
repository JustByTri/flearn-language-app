class RefundDetail {
  final String refundRequestId;
  final String purchaseId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String? studentAvatar;
  final String courseName;
  final int refundAmount;
  final int originalAmount;
  final String requestType;
  final String reason;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountHolderName;
  final String? proofImageUrl;
  final String status;
  final String requestedAt;
  final String? processedAt;
  final String? adminNote;
  final String? processedByAdminName;

  RefundDetail({
    required this.refundRequestId,
    required this.purchaseId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    this.studentAvatar,
    required this.courseName,
    required this.refundAmount,
    required this.originalAmount,
    required this.requestType,
    required this.reason,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountHolderName,
    this.proofImageUrl,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.adminNote,
    this.processedByAdminName,
  });

  factory RefundDetail.fromJson(Map<String, dynamic> json) {
    return RefundDetail(
      refundRequestId: json['refundRequestId'],
      purchaseId: json['purchaseId'],
      studentId: json['studentId'],
      studentName: json['studentName'],
      studentEmail: json['studentEmail'],
      studentAvatar: json['studentAvatar'],
      courseName: json['courseName'],
      refundAmount: json['refundAmount'],
      originalAmount: json['originalAmount'],
      requestType: json['requestType'],
      reason: json['reason'],
      bankName: json['bankName'],
      bankAccountNumber: json['bankAccountNumber'],
      bankAccountHolderName: json['bankAccountHolderName'],
      proofImageUrl: json['proofImageUrl'],
      status: json['status'],
      requestedAt: json['requestedAt'],
      processedAt: json['processedAt'],
      adminNote: json['adminNote'],
      processedByAdminName: json['processedByAdminName'],
    );
  }
}