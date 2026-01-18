import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'item.dart';

final itemRepositoryProvider = Provider((ref) => ItemRepository(ref.read(apiClientProvider)));

class ItemDraft {
  final String name;
  final double unitPrice;
  final int stock;
  final String currency;
  final String? description;
  final String? sku;
  final String? category;
  final List<String> tags;
  final String? barcode;
  final int? reorderPoint;
  final int? minStock;
  final int? maxStock;
  final String? warehouseAisle;
  final String? binLocation;
  final String? imageUrl;
  final bool isActive;
  final bool aiVerified;
  final double? aiConfidence;
  final int? supplierId;
  final int? organizationId;

  ItemDraft({
    required this.name,
    required this.unitPrice,
    required this.stock,
    this.currency = 'USD',
    this.description,
    this.sku,
    this.category,
    this.tags = const [],
    this.barcode,
    this.reorderPoint,
    this.minStock,
    this.maxStock,
    this.warehouseAisle,
    this.binLocation,
    this.imageUrl,
    this.isActive = true,
    this.aiVerified = false,
    this.aiConfidence,
    this.supplierId,
    this.organizationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit_price': unitPrice,
      'stock': stock,
      'currency': currency,
      if (description != null) 'description': description,
      if (sku != null && sku!.isNotEmpty) 'sku': sku,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (tags.isNotEmpty) 'tags': tags,
      if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
      if (reorderPoint != null) 'reorder_point': reorderPoint,
      if (minStock != null) 'min_stock': minStock,
      if (maxStock != null) 'max_stock': maxStock,
      if (warehouseAisle != null && warehouseAisle!.isNotEmpty) 'warehouse_aisle': warehouseAisle,
      if (binLocation != null && binLocation!.isNotEmpty) 'bin_location': binLocation,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
      'is_active': isActive,
      'ai_verified': aiVerified,
      if (aiConfidence != null) 'ai_confidence': aiConfidence,
      if (supplierId != null) 'supplier_id': supplierId,
      if (organizationId != null) 'organization_id': organizationId,
    };
  }
}

class ItemRepository {
  final ApiClient _client;

  ItemRepository(this._client);

  Future<List<Item>> fetchItems() async {
    final response = await _client.get('/items/');
    return (response.data as List)
        .map((e) => Item.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Item> fetchItem(int id) async {
    final response = await _client.get('/items/$id');
    return Item.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Item> createItem(ItemDraft draft) async {
    final response = await _client.post('/items/', data: draft.toJson());
    return Item.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Item> updateItem(int id, ItemDraft draft) async {
    final response = await _client.put('/items/$id', data: draft.toJson());
    return Item.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteItem(int id) async {
    await _client.delete('/items/$id');
  }
}
