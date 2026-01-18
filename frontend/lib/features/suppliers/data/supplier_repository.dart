import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'supplier.dart';

final supplierRepositoryProvider = Provider((ref) => SupplierRepository(ref.read(apiClientProvider)));

class SupplierDraft {
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

  SupplierDraft({
    required this.name,
    this.companyName,
    this.contactName,
    this.email,
    this.phone,
    this.address,
    this.taxId,
    this.status = 'active',
    this.logoUrl,
    this.category,
    this.supplierCode,
    this.isActive = true,
    this.organizationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (companyName != null) 'company_name': companyName,
      if (contactName != null) 'contact_name': contactName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (taxId != null) 'tax_id': taxId,
      'status': status,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (category != null) 'category': category,
      if (supplierCode != null) 'supplier_code': supplierCode,
      'is_active': isActive,
      if (organizationId != null) 'organization_id': organizationId,
    };
  }
}

class SupplierRepository {
  final ApiClient _client;

  SupplierRepository(this._client);

  Future<List<Supplier>> fetchSuppliers() async {
    final response = await _client.get('/suppliers/');
    return (response.data as List)
        .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Supplier> fetchSupplier(int id) async {
    final response = await _client.get('/suppliers/$id');
    return Supplier.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Supplier> createSupplier(SupplierDraft draft) async {
    final response = await _client.post('/suppliers/', data: draft.toJson());
    return Supplier.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Supplier> updateSupplier(int id, SupplierDraft draft) async {
    final response = await _client.put('/suppliers/$id', data: draft.toJson());
    return Supplier.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSupplier(int id) async {
    await _client.delete('/suppliers/$id');
  }
}
