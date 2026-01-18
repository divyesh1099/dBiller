import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'order.dart';

final orderRepositoryProvider = Provider((ref) => OrderRepository(ref.read(apiClientProvider)));

class OrderLineDraft {
  final int? itemId;
  final String? description;
  final String? sku;
  final String? imageUrl;
  final int quantity;
  final double? unitPrice;
  final bool aiVerified;
  final double? aiConfidence;

  OrderLineDraft({
    required this.quantity,
    this.itemId,
    this.description,
    this.sku,
    this.imageUrl,
    this.unitPrice,
    this.aiVerified = false,
    this.aiConfidence,
  });

  Map<String, dynamic> toJson() {
    return {
      if (itemId != null) 'item_id': itemId,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (sku != null && sku!.isNotEmpty) 'sku': sku,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
      'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (aiVerified) 'ai_verified': aiVerified,
      if (aiConfidence != null) 'ai_confidence': aiConfidence,
    };
  }
}

class OrderDraft {
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
  final int? organizationId;
  final int? userId;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? expectedDeliveryAt;
  final List<OrderLineDraft> items;

  OrderDraft({
    required this.status,
    required this.items,
    this.orderType,
    this.supplierId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.billingAddress,
    this.shippingAddress,
    this.notes,
    this.shippingFee = 0,
    this.tax = 0,
    this.currency = 'USD',
    this.organizationId,
    this.userId,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.expectedDeliveryAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (orderType != null && orderType!.isNotEmpty) 'order_type': orderType,
      if (supplierId != null) 'supplier_id': supplierId,
      if (customerName != null && customerName!.isNotEmpty) 'customer_name': customerName,
      if (customerEmail != null && customerEmail!.isNotEmpty) 'customer_email': customerEmail,
      if (customerPhone != null && customerPhone!.isNotEmpty) 'customer_phone': customerPhone,
      if (billingAddress != null && billingAddress!.isNotEmpty) 'billing_address': billingAddress,
      if (shippingAddress != null && shippingAddress!.isNotEmpty) 'shipping_address': shippingAddress,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'shipping_fee': shippingFee,
      'tax': tax,
      'currency': currency,
      if (organizationId != null) 'organization_id': organizationId,
      if (userId != null) 'user_id': userId,
      if (confirmedAt != null) 'confirmed_at': confirmedAt!.toIso8601String(),
      if (shippedAt != null) 'shipped_at': shippedAt!.toIso8601String(),
      if (deliveredAt != null) 'delivered_at': deliveredAt!.toIso8601String(),
      if (cancelledAt != null) 'cancelled_at': cancelledAt!.toIso8601String(),
      if (expectedDeliveryAt != null) 'expected_delivery_at': expectedDeliveryAt!.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderRepository {
  final ApiClient _client;

  OrderRepository(this._client);

  Future<List<Order>> fetchOrders() async {
    final response = await _client.get('/orders/');
    return (response.data as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> fetchOrder(int id) async {
    final response = await _client.get('/orders/$id');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Order> createOrder(OrderDraft draft) async {
    final response = await _client.post('/orders/', data: draft.toJson());
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Order> updateOrder(int id, OrderDraft draft) async {
    final response = await _client.put('/orders/$id', data: draft.toJson());
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteOrder(int id) async {
    await _client.delete('/orders/$id');
  }
}
