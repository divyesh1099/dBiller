import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'invoice_form_screen.dart';
import 'invoices_controller.dart';

class InvoiceEditScreen extends ConsumerWidget {
  final int invoiceId;

  const InvoiceEditScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceProvider(invoiceId));
    return invoiceAsync.when(
      data: (invoice) => InvoiceFormScreen(initial: invoice),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
