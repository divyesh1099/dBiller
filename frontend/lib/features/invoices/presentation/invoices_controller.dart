import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/invoice.dart';
import '../data/invoice_repository.dart';

final invoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  return ref.read(invoiceRepositoryProvider).fetchInvoices();
});

final invoiceProvider = FutureProvider.family<Invoice, int>((ref, id) async {
  return ref.read(invoiceRepositoryProvider).fetchInvoice(id);
});
