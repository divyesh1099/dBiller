import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'order_form_screen.dart';
import 'orders_controller.dart';

class OrderEditScreen extends ConsumerWidget {
  final int orderId;

  const OrderEditScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));
    return orderAsync.when(
      data: (order) => OrderFormScreen(initial: order),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
