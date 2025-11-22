class SubscriptionPurchaseMeta {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  SubscriptionPurchaseMeta({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory SubscriptionPurchaseMeta.fromJson(Map<String, dynamic> json) {
    return SubscriptionPurchaseMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class SubscriptionPurchase {
  final String purchaseId;
  final String subscriptionId;
  final String subscriptionType;
  final int conversationQuota;
  final int price;
  final int finalAmount;
  final int? discountAmount;
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
  final dynamic subscriptionDetails;

  SubscriptionPurchase({
    required this.purchaseId,
    required this.subscriptionId,
    required this.subscriptionType,
    required this.conversationQuota,
    required this.price,
    required this.finalAmount,
    this.discountAmount,
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
    this.subscriptionDetails,
  });

  factory SubscriptionPurchase.fromJson(Map<String, dynamic> json) {
    return SubscriptionPurchase(
      purchaseId: json['purchaseId'] ?? '',
      subscriptionId: json['subscriptionId'] ?? '',
      subscriptionType: json['subscriptionType'] ?? '',
      conversationQuota: (json['conversationQuota'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toInt() ?? 0,
      finalAmount: (json['finalAmount'] as num?)?.toInt() ?? 0,
      discountAmount: json['discountAmount'] != null ? (json['discountAmount'] as num).toInt() : null,
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
      subscriptionDetails: json['subscriptionDetails'],
    );
  }
}