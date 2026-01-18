import '../../../core/json_utils.dart';
import '../../../core/url_utils.dart';

class Supplier {
  final int id;
  final String name;
  final String? companyName;
  final String? contactName;
  final String? email;
  final String? phone;
  final String? address;
  final String? taxId;
  final String status;
  final String? logoUrl;
  final String? category;
  final String? supplierCode;
  final bool isActive;
  final int? organizationId;
  final DateTime? createdAt;

  Supplier({
    required this.id,
    required this.name,
    required this.status,
    this.companyName,
    this.contactName,
    this.email,
    this.phone,
    this.address,
    this.taxId,
    this.logoUrl,
    this.category,
    this.supplierCode,
    this.isActive = true,
    this.organizationId,
    this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: readInt(json['id']),
      name: (json['name'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      companyName: json['company_name'] as String?,
      contactName: json['contact_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      taxId: json['tax_id'] as String?,
      logoUrl: resolveMediaUrl(json['logo_url'] as String?),
      category: json['category'] as String?,
      supplierCode: json['supplier_code'] as String?,
      isActive: readBool(json['is_active'], fallback: true),
      organizationId: json['organization_id'] == null ? null : readInt(json['organization_id']),
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}
