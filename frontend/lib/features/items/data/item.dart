import '../../../core/json_utils.dart';
import '../../../core/url_utils.dart';

class Item {
  final int id;
  final String name;
  final String? description;
  final String? sku;
  final String? category;
  final List<String> tags;
  final String? barcode;
  final double unitPrice;
  final String currency;
  final int stock;
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
  final DateTime? createdAt;

  Item({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.stock,
    required this.currency,
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
    this.createdAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: readInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      barcode: json['barcode'] as String?,
      unitPrice: readDouble(json['unit_price']),
      currency: (json['currency'] ?? 'USD').toString(),
      stock: readInt(json['stock']),
      reorderPoint: json['reorder_point'] == null ? null : readInt(json['reorder_point']),
      minStock: json['min_stock'] == null ? null : readInt(json['min_stock']),
      maxStock: json['max_stock'] == null ? null : readInt(json['max_stock']),
      warehouseAisle: json['warehouse_aisle'] as String?,
      binLocation: json['bin_location'] as String?,
      imageUrl: resolveMediaUrl(json['image_url'] as String?),
      isActive: readBool(json['is_active'], fallback: true),
      aiVerified: readBool(json['ai_verified']),
      aiConfidence: json['ai_confidence'] == null ? null : readDouble(json['ai_confidence']),
      supplierId: json['supplier_id'] == null ? null : readInt(json['supplier_id']),
      organizationId: json['organization_id'] == null ? null : readInt(json['organization_id']),
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}
