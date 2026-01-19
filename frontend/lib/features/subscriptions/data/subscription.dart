import '../../../core/json_utils.dart';

class SubscriptionPlan {
  final int id;
  final String name;
  final double? price;
  final String currency;
  final double? monthlyPrice;
  final double? annualPrice;
  final List<String> features;
  final Map<String, dynamic> limits;
  final String? description;
  final String? badgeText;
  final bool isFeatured;
  final bool isActive;
  final DateTime? createdAt;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.currency,
    this.price,
    this.monthlyPrice,
    this.annualPrice,
    this.features = const [],
    this.limits = const {},
    this.description,
    this.badgeText,
    this.isFeatured = false,
    this.isActive = true,
    this.createdAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: readInt(json['id']),
      name: (json['name'] ?? '').toString(),
      price: json['price'] == null ? null : readDouble(json['price']),
      currency: (json['currency'] ?? 'USD').toString(),
      monthlyPrice: json['monthly_price'] == null ? null : readDouble(json['monthly_price']),
      annualPrice: json['annual_price'] == null ? null : readDouble(json['annual_price']),
      features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      limits: (json['limits'] as Map<String, dynamic>?) ?? const {},
      description: json['description'] as String?,
      badgeText: json['badge_text'] as String?,
      isFeatured: readBool(json['is_featured']),
      isActive: readBool(json['is_active'], fallback: true),
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}

class OrganizationSubscription {
  final int id;
  final int organizationId;
  final int subscriptionId;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? cancelledAt;
  final double? amount;
  final String currency;
  final String? notes;
  final String? paymentReference;
  final bool refundEligible;
  final SubscriptionPlan? subscription;

  OrganizationSubscription({
    required this.id,
    required this.organizationId,
    required this.subscriptionId,
    required this.status,
    required this.currency,
    required this.refundEligible,
    this.startedAt,
    this.endedAt,
    this.cancelledAt,
    this.amount,
    this.notes,
    this.paymentReference,
    this.subscription,
  });

  factory OrganizationSubscription.fromJson(Map<String, dynamic> json) {
    return OrganizationSubscription(
      id: readInt(json['id']),
      organizationId: readInt(json['organization_id']),
      subscriptionId: readInt(json['subscription_id']),
      status: (json['status'] ?? 'active').toString(),
      startedAt: json['started_at'] == null ? null : DateTime.tryParse(json['started_at'].toString()),
      endedAt: json['ended_at'] == null ? null : DateTime.tryParse(json['ended_at'].toString()),
      cancelledAt: json['cancelled_at'] == null ? null : DateTime.tryParse(json['cancelled_at'].toString()),
      amount: json['amount'] == null ? null : readDouble(json['amount']),
      currency: (json['currency'] ?? 'USD').toString(),
      notes: json['notes'] as String?,
      paymentReference: json['payment_reference'] as String?,
      refundEligible: readBool(json['refund_eligible']),
      subscription: json['subscription'] is Map<String, dynamic>
          ? SubscriptionPlan.fromJson(json['subscription'] as Map<String, dynamic>)
          : null,
    );
  }
}

class RazorpayOrder {
  final String orderId;
  final int amount;
  final String currency;
  final String keyId;
  final int subscriptionId;
  final int? organizationId;

  RazorpayOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
    required this.subscriptionId,
    this.organizationId,
  });

  factory RazorpayOrder.fromJson(Map<String, dynamic> json) {
    return RazorpayOrder(
      orderId: (json['order_id'] ?? '').toString(),
      amount: readInt(json['amount']),
      currency: (json['currency'] ?? 'INR').toString(),
      keyId: (json['key_id'] ?? '').toString(),
      subscriptionId: readInt(json['subscription_id']),
      organizationId: json['organization_id'] == null ? null : readInt(json['organization_id']),
    );
  }
}
