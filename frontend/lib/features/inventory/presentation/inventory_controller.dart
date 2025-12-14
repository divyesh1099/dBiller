import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/inventory_repository.dart';
import '../data/product.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.read(inventoryRepositoryProvider).getProducts();
});
