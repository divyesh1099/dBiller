import '../../../core/json_utils.dart';
import '../../../core/formatters.dart';

class InvoiceItem {
  final int id;
  final int? itemId;
  final String? description;
  final String? sku;
  final String? imageUrl;
  final int quantity;
  final double? unitPrice;
  final double lineTotal;

  InvoiceItem({
    required this.id,
    required this.quantity,
    required this.lineTotal,
    this.itemId,
    this.description,
    this.sku,
    this.imageUrl,
    this.unitPrice,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: readInt(json['id']),
      itemId: json['item_id'] == null ? null : readInt(json['item_id']),
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      imageUrl: json['image_url'] as String?,
      quantity: readInt(json['quantity']),
      unitPrice: json['unit_price'] == null ? null : readDouble(json['unit_price']),
      lineTotal: readDouble(json['line_total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'item_id': itemId,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (imageUrl != null) 'image_url': imageUrl,
      'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
    };
  }
}

class Invoice {
  final int id;
  final String? invoiceNumber;
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
  final double totalAmount;
  final String currency;
  final int? organizationId;
  final int? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.status,
    required this.tax,
    required this.discount,
    required this.totalAmount,
    required this.currency,
    required this.items,
    this.invoiceNumber,
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
    this.organizationId,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return Invoice(
      id: readInt(json['id']),
      invoiceNumber: json['invoice_number'] as String?,
      status: (json['status'] ?? 'draft').toString(),
      issueDate: parseDateTime(json['issue_date']),
      dueDate: parseDateTime(json['due_date']),
      sourceUrl: json['source_url'] as String?,
      sourceType: json['source_type'] as String?,
      aiExtracted: readBool(json['ai_extracted']),
      paidAt: parseDateTime(json['paid_at']),
      customerName: json['customer_name'] as String?,
      customerEmail: json['customer_email'] as String?,
      customerPhone: json['customer_phone'] as String?,
      billingAddress: json['billing_address'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      notes: json['notes'] as String?,
      tax: readDouble(json['tax']),
      discount: readDouble(json['discount']),
      totalAmount: readDouble(json['total_amount']),
      currency: (json['currency'] ?? 'USD').toString(),
      organizationId: json['organization_id'] == null ? null : readInt(json['organization_id']),
      userId: json['user_id'] == null ? null : readInt(json['user_id']),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      items: items,
    );
  }
}
