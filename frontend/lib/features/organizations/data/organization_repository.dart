import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'organization.dart';

final organizationRepositoryProvider = Provider((ref) => OrganizationRepository(ref.read(apiClientProvider)));

class OrganizationDraft {
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

  OrganizationDraft({
    required this.name,
    this.logoUrl,
    this.companyName,
    this.businessType,
    this.taxId,
    this.email,
    this.phone,
    this.address,
    this.status = 'active',
    this.subscriptionId,
    this.trialEndsAt,
    this.currentPeriodEnd,
    this.nodeLimit,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (companyName != null) 'company_name': companyName,
      if (businessType != null) 'business_type': businessType,
      if (taxId != null) 'tax_id': taxId,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      'status': status,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      if (trialEndsAt != null) 'trial_ends_at': trialEndsAt!.toIso8601String(),
      if (currentPeriodEnd != null) 'current_period_end': currentPeriodEnd!.toIso8601String(),
      if (nodeLimit != null) 'node_limit': nodeLimit,
    };
  }
}

class OnboardOrganizationDraft {
  final String organizationName;
  final String adminUsername;
  final String adminPassword;
  final String adminEmail;
  final int? subscriptionId;
  final double? amount;
  final String? currency;
  final String? paymentReference;
  final String? notes;

  OnboardOrganizationDraft({
    required this.organizationName,
    required this.adminUsername,
    required this.adminPassword,
    required this.adminEmail,
    this.subscriptionId,
    this.amount,
    this.currency,
    this.paymentReference,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'organization_name': organizationName,
      'admin_username': adminUsername,
      'admin_password': adminPassword,
      'admin_email': adminEmail,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (paymentReference != null) 'payment_reference': paymentReference,
      if (notes != null) 'notes': notes,
    };
  }
}

class OrganizationRepository {
  final ApiClient _client;

  OrganizationRepository(this._client);

  Future<List<Organization>> fetchOrganizations() async {
    final response = await _client.get('/organizations/');
    return (response.data as List)
        .map((e) => Organization.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Organization> fetchOrganization(int id) async {
    final response = await _client.get('/organizations/$id');
    return Organization.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Organization> createOrganization(OrganizationDraft draft) async {
    final response = await _client.post('/organizations/', data: draft.toJson());
    return Organization.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Organization> updateOrganization(int id, OrganizationDraft draft) async {
    final response = await _client.put('/organizations/$id', data: draft.toJson());
    return Organization.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteOrganization(int id) async {
    await _client.delete('/organizations/$id');
  }

  Future<Organization> onboardOrganization(OnboardOrganizationDraft draft) async {
    final response = await _client.post('/superadmin/organizations/onboard', data: draft.toJson());
    return Organization.fromJson(response.data as Map<String, dynamic>);
  }
}
