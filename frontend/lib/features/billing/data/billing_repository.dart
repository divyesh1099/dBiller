import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api_client.dart';
import '../../inventory/data/product.dart';

class RecognizeResult {
  final List<Product> products;
  final String? debug;
  RecognizeResult({required this.products, this.debug});
}

final billingRepositoryProvider = Provider((ref) => BillingRepository(ref.read(apiClientProvider)));

class BillingRepository {
  final ApiClient _client;

  BillingRepository(this._client);

  Future<void> createBill(List<CartItem> items, String paymentMethod) async {
    await _client.post('/bills/', data: {
      'items': items.map((e) => {'product_id': e.product.id, 'quantity': e.quantity}).toList(),
      'payment_method': paymentMethod,
    });
  }

  Future<RecognizeResult> recognizeProducts(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: imageFile.name),
    });
    final response = await _client.post(
      '/recognize/',
      queryParameters: {'debug': true},
      data: formData,
    );
    final data = response.data;
    if (data is List) {
      return RecognizeResult(
        products: (data).map((e) => Product.fromJson(e)).toList(),
      );
    }
    if (data is Map<String, dynamic>) {
      final productsJson = (data['products'] as List? ?? []);
      final debug = data['debug']?.toString();
      return RecognizeResult(
        products: productsJson.map((e) => Product.fromJson(e)).toList(),
        debug: debug,
      );
    }
    return RecognizeResult(products: []);
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}
