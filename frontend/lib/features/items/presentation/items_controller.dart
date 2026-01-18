import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/item_repository.dart';
import '../data/item.dart';

final itemsProvider = FutureProvider<List<Item>>((ref) async {
  return ref.read(itemRepositoryProvider).fetchItems();
});

final itemProvider = FutureProvider.family<Item, int>((ref, id) async {
  return ref.read(itemRepositoryProvider).fetchItem(id);
});
