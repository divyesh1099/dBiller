import '../../../core/json_utils.dart';
import '../../../core/formatters.dart';

class OrderItem {
  final int id;
  final int? itemId;
  final String? description;
  final String? sku;
  final String? imageUrl;
  final int quantity;
  final double? unitPrice;
  final double lineTotal;
  final bool aiVerified;
  final double? aiConfidence;

  OrderItem({
    required this.id,
    required this.quantity,
    required this.lineTotal,
    this.itemId,
    this.description,
    this.sku,
    this.imageUrl,
    this.unitPrice,
    this.aiVerified = false,
    this.aiConfidence,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: readInt(json['id']),
      itemId: json['item_id'] == null ? null : readInt(json['item_id']),
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      imageUrl: json['image_url'] as String?,
      quantity: readInt(json['quantity']),
      unitPrice: json['unit_price'] == null ? null : readDouble(json['unit_price']),
      lineTotal: readDouble(json['line_total']),
      aiVerified: readBool(json['ai_verified']),
      aiConfidence: json['ai_confidence'] == null ? null : readDouble(json['ai_confidence']),
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
      if (aiVerified) 'ai_verified': aiVerified,
      if (aiConfidence != null) 'ai_confidence': aiConfidence,
    };
  }
}

class Order {
  final int id;
  final String? orderNumber;
  final String status;
  final String? orderType;
  final int? supplierId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? billingAddress;
  final String? shippingAddress;
  final String? notes;
  final double shippingFee;
  final double tax;
  final String currency;
  final double subtotal;
  final double totalAmount;
  final int? organizationId;
  final int? userId;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? expectedDeliveryAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.status,
    required this.shippingFee,
    required this.tax,
    required this.currency,
    required this.subtotal,
    required this.totalAmount,
    required this.items,
    this.orderNumber,
    this.orderType,
    this.supplierId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.billingAddress,
    this.shippingAddress,
    this.notes,
    this.organizationId,
    this.userId,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.expectedDeliveryAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return Order(
      id: readInt(json['id']),
      orderNumber: json['order_number'] as String?,
      status: (json['status'] ?? 'pending').toString(),
      orderType: json['order_type'] as String?,
      supplierId: json['supplier_id'] == null ? null : readInt(json['supplier_id']),
      customerName: json['customer_name'] as String?,
      customerEmail: json['customer_email'] as String?,
      customerPhone: json['customer_phone'] as String?,
      billingAddress: json['billing_address'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      notes: json['notes'] as String?,
      shippingFee: readDouble(json['shipping_fee']),
      tax: readDouble(json['tax']),
      currency: (json['currency'] ?? 'USD').toString(),
      subtotal: readDouble(json['subtotal']),
      totalAmount: readDouble(json['total_amount']),
      organizationId: json['organization_id'] == null ? null : readInt(json['organization_id']),
      userId: json['user_id'] == null ? null : readInt(json['user_id']),
      confirmedAt: parseDateTime(json['confirmed_at']),
      shippedAt: parseDateTime(json['shipped_at']),
      deliveredAt: parseDateTime(json['delivered_at']),
      cancelledAt: parseDateTime(json['cancelled_at']),
      expectedDeliveryAt: parseDateTime(json['expected_delivery_at']),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      items: items,
    );
  }
}
