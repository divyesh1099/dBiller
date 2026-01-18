import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/supplier.dart';
import '../data/supplier_repository.dart';

final suppliersProvider = FutureProvider<List<Supplier>>((ref) async {
  return ref.read(supplierRepositoryProvider).fetchSuppliers();
});

final supplierProvider = FutureProvider.family<Supplier, int>((ref, id) async {
  return ref.read(supplierRepositoryProvider).fetchSupplier(id);
});
