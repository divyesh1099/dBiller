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
