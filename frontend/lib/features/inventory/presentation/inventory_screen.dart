import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/product.dart';
import 'inventory_controller.dart';
import '../data/inventory_repository.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _isUploading = false;

  Future<void> _bulkUpload() async {
    final pickResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (pickResult == null || pickResult.files.isEmpty) return;
    final file = pickResult.files.single;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please retry; failed to read CSV bytes.')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      final result = await ref.read(inventoryRepositoryProvider).bulkUploadProducts(
        fileBytes: file.bytes!.toList(),
        filename: file.name,
      );
      ref.refresh(productsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${result['created']} items. Skipped ${result['skipped']}.')),
        );
        final errors = result['errors'];
        if (errors is List && errors.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('First error: ${errors.first}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bulk upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          TextButton.icon(
            onPressed: _isUploading ? null : _bulkUpload,
            icon: const Icon(Icons.upload_file),
            label: Text(_isUploading ? 'Uploading...' : 'Bulk CSV'),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          final Map<String, List<Product>> byCategory = {};
          for (final p in products) {
            final cat = (p.category ?? 'Uncategorized').isNotEmpty ? (p.category ?? 'Uncategorized') : 'Uncategorized';
            byCategory.putIfAbsent(cat, () => []).add(p);
          }
          final entries = byCategory.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, idx) {
              final entry = entries[idx];
              return ExpansionTile(
                title: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    if (entry.key != 'Uncategorized')
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
                          try {
                            await ref.read(inventoryRepositoryProvider).deleteCategory(entry.key);
                            ref.refresh(productsProvider);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete category failed: $e')));
                            }
                          }
                        },
                      ),
                  ],
                ),
                children: entry.value.map((product) {
                  return ListTile(
                    leading: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                          )
                        : const Icon(Icons.image_not_supported),
                    title: Text(product.name),
                    subtitle: Text(
                      [
                        if (product.category != null && product.category!.isNotEmpty)
                          'Category: ${product.category}',
                        'Stock: ${product.stock}',
                      ].join(' • '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            context.push('/inventory/add', extra: product);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete product?'),
                                content: Text('Delete "${product.name}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await ref.read(inventoryRepositoryProvider).deleteProduct(product.id);
                              ref.refresh(productsProvider);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inventory/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
