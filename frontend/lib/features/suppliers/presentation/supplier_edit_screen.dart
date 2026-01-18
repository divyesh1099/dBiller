import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supplier_form_screen.dart';
import 'suppliers_controller.dart';

class SupplierEditScreen extends ConsumerWidget {
  final int supplierId;

  const SupplierEditScreen({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierAsync = ref.watch(supplierProvider(supplierId));
    return supplierAsync.when(
      data: (supplier) => SupplierFormScreen(initial: supplier),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
