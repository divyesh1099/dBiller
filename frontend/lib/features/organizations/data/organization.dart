import '../../../core/json_utils.dart';
import '../../../core/formatters.dart';
import '../../../core/url_utils.dart';

class Organization {
  final int id;
  final String name;
  final String? logoUrl;
  final String? companyName;
  final String? businessType;
  final String? taxId;
  final String? email;
  final String? phone;
  final String? address;
  final String status;
  final int? subscriptionId;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEnd;
  final int? nodeLimit;
  final DateTime? createdAt;

  Organization({
    required this.id,
    required this.name,
    required this.status,
    this.logoUrl,
    this.companyName,
    this.businessType,
    this.taxId,
    this.email,
    this.phone,
    this.address,
    this.subscriptionId,
    this.trialEndsAt,
    this.currentPeriodEnd,
    this.nodeLimit,
    this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: readInt(json['id']),
      name: (json['name'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      logoUrl: resolveMediaUrl(json['logo_url'] as String?),
      companyName: json['company_name'] as String?,
      businessType: json['business_type'] as String?,
      taxId: json['tax_id'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      subscriptionId: json['subscription_id'] == null ? null : readInt(json['subscription_id']),
      trialEndsAt: parseDateTime(json['trial_ends_at']),
      currentPeriodEnd: parseDateTime(json['current_period_end']),
      nodeLimit: json['node_limit'] == null ? null : readInt(json['node_limit']),
      createdAt: parseDateTime(json['created_at']),
    );
  }
}
