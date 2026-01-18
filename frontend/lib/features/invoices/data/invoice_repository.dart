import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'invoice.dart';

final invoiceRepositoryProvider = Provider((ref) => InvoiceRepository(ref.read(apiClientProvider)));

class InvoiceLineDraft {
  final int? itemId;
  final String? description;
  final String? sku;
  final String? imageUrl;
  final int quantity;
  final double? unitPrice;

  InvoiceLineDraft({
    required this.quantity,
    this.itemId,
    this.description,
    this.sku,
    this.imageUrl,
    this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'item_id': itemId,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (sku != null && sku!.isNotEmpty) 'sku': sku,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
      'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
    };
  }
}

class InvoiceDraft {
  final String status;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String? sourceUrl;
  final String? sourceType;
  final bool aiExtracted;
  final DateTime? paidAt;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? billingAddress;
  final String? shippingAddress;
  final String? notes;
  final double tax;
  final double discount;
  final String currency;
  final int? organizationId;
  final int? userId;
  final List<InvoiceLineDraft> items;

  InvoiceDraft({
    required this.status,
    required this.items,
    this.issueDate,
    this.dueDate,
    this.sourceUrl,
    this.sourceType,
    this.aiExtracted = false,
    this.paidAt,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.billingAddress,
    this.shippingAddress,
    this.notes,
    this.tax = 0,
    this.discount = 0,
    this.currency = 'USD',
    this.organizationId,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (issueDate != null) 'issue_date': issueDate!.toIso8601String(),
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      if (sourceUrl != null && sourceUrl!.isNotEmpty) 'source_url': sourceUrl,
      if (sourceType != null && sourceType!.isNotEmpty) 'source_type': sourceType,
      'ai_extracted': aiExtracted,
      if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
      if (customerName != null && customerName!.isNotEmpty) 'customer_name': customerName,
      if (customerEmail != null && customerEmail!.isNotEmpty) 'customer_email': customerEmail,
      if (customerPhone != null && customerPhone!.isNotEmpty) 'customer_phone': customerPhone,
      if (billingAddress != null && billingAddress!.isNotEmpty) 'billing_address': billingAddress,
      if (shippingAddress != null && shippingAddress!.isNotEmpty) 'shipping_address': shippingAddress,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'tax': tax,
      'discount': discount,
      'currency': currency,
      if (organizationId != null) 'organization_id': organizationId,
      if (userId != null) 'user_id': userId,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class InvoiceRepository {
  final ApiClient _client;

  InvoiceRepository(this._client);

  Future<List<Invoice>> fetchInvoices() async {
    final response = await _client.get('/invoices/');
    return (response.data as List)
        .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Invoice> fetchInvoice(int id) async {
    final response = await _client.get('/invoices/$id');
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Invoice> createInvoice(InvoiceDraft draft) async {
    final response = await _client.post('/invoices/', data: draft.toJson());
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Invoice> updateInvoice(int id, InvoiceDraft draft) async {
    final response = await _client.put('/invoices/$id', data: draft.toJson());
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteInvoice(int id) async {
    await _client.delete('/invoices/$id');
  }
}
