import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../data/supplier.dart';
import 'suppliers_controller.dart';

class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onBack: () => context.pop()),
            _SearchBar(controller: _searchController, onChanged: (_) => setState(() {})),
            Expanded(
              child: suppliersAsync.when(
                data: (suppliers) {
                  final query = _searchController.text.toLowerCase();
                  final filtered = suppliers.where((supplier) {
                    return supplier.name.toLowerCase().contains(query) ||
                        (supplier.contactName ?? '').toLowerCase().contains(query) ||
                        (supplier.supplierCode ?? '').toLowerCase().contains(query);
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No suppliers found.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final supplier = filtered[index];
                      return _SupplierRow(
                        supplier: supplier,
                        onTap: () => context.push('/suppliers/${supplier.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/suppliers/new'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          const Expanded(
            child: Center(
              child: Text('Supplier Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name or ID',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _SupplierRow extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onTap;

  const _SupplierRow({required this.supplier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(supplier.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.1),
                backgroundImage: supplier.logoUrl != null ? NetworkImage(supplier.logoUrl!) : null,
                child: supplier.logoUrl == null
                    ? Text(
                        supplier.name.isNotEmpty ? supplier.name[0] : 'S',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            supplier.status,
                            style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contact: ${supplier.contactName ?? '-'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supplier.phone ?? '',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.call, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
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
}
