import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order.dart';
import '../data/order_repository.dart';

final ordersProvider = FutureProvider<List<Order>>((ref) async {
  return ref.read(orderRepositoryProvider).fetchOrders();
});

final orderProvider = FutureProvider.family<Order, int>((ref, id) async {
  return ref.read(orderRepositoryProvider).fetchOrder(id);
});
