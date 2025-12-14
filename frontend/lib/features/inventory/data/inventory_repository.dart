import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api_client.dart';
import '../../../../core/config.dart';
import 'product.dart';

final inventoryRepositoryProvider = Provider((ref) => InventoryRepository(ref.read(apiClientProvider)));

class InventoryRepository {
  final ApiClient _client;

  InventoryRepository(this._client);

  Future<List<Product>> getProducts() async {
    final response = await _client.get('/products/');
    return (response.data as List).map((e) => _withBaseUrl(Product.fromJson(e))).toList();
  }

  Future<Product> addProduct({
    required String name,
    required double price,
    required int stock,
    XFile? imageFile,
    String? imageUrl,
    String? category,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'price': price,
      'stock': stock,
      if (category != null && category.isNotEmpty) 'category': category,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
    });

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      formData.files.add(
        MapEntry(
          'image',
          MultipartFile.fromBytes(
            bytes,
            filename: imageFile.name,
          ),
        ),
      );
    }

    final response = await _client.post('/products/', data: formData);
    return _withBaseUrl(Product.fromJson(response.data));
  }

  Future<Map<String, dynamic>> bulkUploadProducts({
    required List<int> fileBytes,
    required String filename,
    String? category,
  }) async {
    final formData = FormData.fromMap({
      if (category != null && category.isNotEmpty) 'category': category,
      'file': MultipartFile.fromBytes(fileBytes, filename: filename),
    });

    final response = await _client.post('/products/bulk_upload', data: formData);
    return response.data as Map<String, dynamic>;
  }

  Future<Product> updateProduct({
    required int id,
    required String name,
    required double price,
    required int stock,
    String? category,
    XFile? imageFile,
    String? imageUrl,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'price': price,
      'stock': stock,
      if (category != null && category.isNotEmpty) 'category': category,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
    });
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      formData.files.add(
        MapEntry(
          'image',
          MultipartFile.fromBytes(
            bytes,
            filename: imageFile.name,
          ),
        ),
      );
    }
    final response = await _client.put('/products/$id', data: formData);
    return _withBaseUrl(Product.fromJson(response.data));
  }

  Future<void> deleteProduct(int id) async {
    await _client.delete('/products/$id');
  }

  Future<void> deleteCategory(String category) async {
    await _client.delete('/categories/$category');
  }

  Product _withBaseUrl(Product p) {
    if (p.imageUrl == null) return p;
    String url = p.imageUrl!;
    final base = AppConfig.instance.apiBaseUrl;

    // Fix legacy localhost URLs on Android
    if (url.contains('http://localhost:8001') && base.contains('10.0.2.2')) {
       url = url.replaceFirst('http://localhost:8001', 'http://10.0.2.2:8001');
    }

    if (!url.startsWith('http')) {
      // Relative path: prepend current base
      p = p.copyWith(imageUrl: '$base$url');
    } else {
      // Already absolute, but check if we rewrote it
      p = p.copyWith(imageUrl: url);
    }
    return p;
  }
}
