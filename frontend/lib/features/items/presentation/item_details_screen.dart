import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/formatters.dart';
import '../data/item.dart';
import '../data/item_repository.dart';
import 'items_controller.dart';

class ItemDetailsScreen extends ConsumerWidget {
  final int itemId;

  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemProvider(itemId));
    return Scaffold(
      body: itemAsync.when(
        data: (item) => _ItemDetailsBody(item: item),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ItemDetailsBody extends ConsumerWidget {
  final Item item;

  const _ItemDetailsBody({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLow = item.reorderPoint != null && item.stock <= item.reorderPoint!;
    final isCritical = item.minStock != null && item.stock <= item.minStock!;
    final stockColor = isCritical
        ? Colors.red
        : isLow
            ? Colors.orange
            : Colors.green;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => context.pop(),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 18),
                      SizedBox(width: 6),
                      Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Text(
                  'Item Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      color: Colors.white.withOpacity(0.08),
                      height: 260,
                      child: item.imageUrl != null
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.photo, color: Colors.white38, size: 40)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.description ?? 'No description',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.inventory_2, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Current Stock Level',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: stockColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isCritical
                                    ? 'Critical'
                                    : isLow
                                        ? 'Low'
                                        : 'In Stock',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stockColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              item.stock.toString(),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '/ ${item.maxStock ?? '-'} units',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: item.maxStock == null || item.maxStock == 0
                                ? 0
                                : item.stock / item.maxStock!,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Specifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _SpecCard(label: 'SKU', value: item.sku ?? '-'),
                          _SpecCard(label: 'Category', value: item.category ?? '-'),
                          _SpecCard(
                            label: 'Price',
                            value: formatCurrency(item.unitPrice, currency: item.currency),
                          ),
                          _SpecCard(label: 'Barcode', value: item.barcode ?? '-'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _BottomActions(item: item),
        ],
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  final String label;
  final String value;

  const _SpecCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BottomActions extends ConsumerWidget {
  final Item item;

  const _BottomActions({required this.item});

  Future<void> _adjustStock(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: item.stock.toString());
    final newStock = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Stock'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New stock'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newStock == null) return;
    final repo = ref.read(itemRepositoryProvider);
    await repo.updateItem(
      item.id,
      ItemDraft(
        name: item.name,
        unitPrice: item.unitPrice,
        stock: newStock,
        currency: item.currency,
        description: item.description,
        sku: item.sku,
        category: item.category,
        tags: item.tags,
        barcode: item.barcode,
        reorderPoint: item.reorderPoint,
        minStock: item.minStock,
        maxStock: item.maxStock,
        warehouseAisle: item.warehouseAisle,
        binLocation: item.binLocation,
        imageUrl: item.imageUrl,
        isActive: item.isActive,
        aiVerified: item.aiVerified,
        aiConfidence: item.aiConfidence,
        supplierId: item.supplierId,
        organizationId: item.organizationId,
      ),
    );
    ref.refresh(itemProvider(item.id));
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(itemRepositoryProvider).deleteItem(item.id);
    ref.invalidate(itemsProvider);
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
          IconButton(
            onPressed: () => context.push('/inventory/items/${item.id}/edit'),
            icon: const Icon(Icons.edit),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _adjustStock(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: const Text('Adjust Stock', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _deleteItem(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
