import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../data/supplier.dart';
import '../data/supplier_repository.dart';
import 'suppliers_controller.dart';

class SupplierDetailsScreen extends ConsumerWidget {
  final int supplierId;

  const SupplierDetailsScreen({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierAsync = ref.watch(supplierProvider(supplierId));
    return Scaffold(
      body: supplierAsync.when(
        data: (supplier) => _SupplierDetailsBody(supplier: supplier),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SupplierDetailsBody extends ConsumerWidget {
  final Supplier supplier;

  const _SupplierDetailsBody({required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(supplier.status);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new)),
                const Expanded(
                  child: Center(
                    child: Text('Supplier Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    backgroundImage: supplier.logoUrl != null ? NetworkImage(supplier.logoUrl!) : null,
                    child: supplier.logoUrl == null
                        ? Text(
                            supplier.name.isNotEmpty ? supplier.name[0] : 'S',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    supplier.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      supplier.status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _InfoTile(label: 'Contact Name', value: supplier.contactName ?? '-'),
                _InfoTile(label: 'Email', value: supplier.email ?? '-'),
                _InfoTile(label: 'Phone', value: supplier.phone ?? '-'),
                _InfoTile(label: 'Address', value: supplier.address ?? '-'),
                _InfoTile(label: 'Category', value: supplier.category ?? '-'),
                _InfoTile(label: 'Supplier Code', value: supplier.supplierCode ?? '-'),
              ],
            ),
          ),
          _BottomActions(supplier: supplier),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends ConsumerWidget {
  final Supplier supplier;

  const _BottomActions({required this.supplier});

  Future<void> _deleteSupplier(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: const Text('Are you sure you want to delete this supplier?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(supplierRepositoryProvider).deleteSupplier(supplier.id);
    ref.invalidate(suppliersProvider);
    if (context.mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/suppliers/${supplier.id}/edit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('Edit Supplier', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: () => _deleteSupplier(context, ref), icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return Colors.green;
    case 'pending':
      return Colors.orange;
    case 'inactive':
      return Colors.grey;
    default:
      return Colors.blueGrey;
  }
}
