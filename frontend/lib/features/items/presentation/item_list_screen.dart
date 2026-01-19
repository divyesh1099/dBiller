import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/formatters.dart';
import '../data/item.dart';
import 'items_controller.dart';

class ItemListScreen extends ConsumerStatefulWidget {
  const ItemListScreen({super.key});

  @override
  ConsumerState<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends ConsumerState<ItemListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onSettings: () => context.push('/settings')),
            Expanded(
              child: itemsAsync.when(
                data: (items) {
                  final categories = <String>{'All'};
                  for (final item in items) {
                    if ((item.category ?? '').isNotEmpty) {
                      categories.add(item.category!);
                    }
                  }
                  final query = _searchController.text.toLowerCase();
                  final filtered = items.where((item) {
                    final matchesQuery = item.name.toLowerCase().contains(query) ||
                        (item.sku ?? '').toLowerCase().contains(query) ||
                        (item.category ?? '').toLowerCase().contains(query);
                    final matchesCategory =
                        _selectedCategory == 'All' || item.category == _selectedCategory;
                    return matchesQuery && matchesCategory;
                  }).toList();
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 90),
                    children: [
                      _ScanButton(
                        onTap: () => context.push('/ai-scanner'),
                      ),
                      _SearchBar(controller: _searchController, onChanged: (_) => setState(() {})),
                      _CategoryChips(
                        categories: categories.toList(),
                        selected: _selectedCategory,
                        onSelected: (value) => setState(() => _selectedCategory = value),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _ItemCard(
                              item: item,
                              onTap: () => context.push('/inventory/items/${item.id}'),
                            );
                          },
                        ),
                      ),
                    ],
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
        onPressed: () => context.push('/inventory/items/new'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onSettings;

  const _TopBar({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'Inventory',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
              IconButton(
                onPressed: onSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onTap,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera, color: Colors.white),
            SizedBox(width: 8),
            Text('Scan to Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 4),
            Text('AI', style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name, SKU or category',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          return ChoiceChip(
            label: Text(category, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const _ItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLow = item.reorderPoint != null && item.stock <= item.reorderPoint!;
    final isCritical = item.minStock != null && item.stock <= item.minStock!;
    final badgeColor = isCritical
        ? Colors.red
        : isLow
            ? Colors.orange
            : Colors.green;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      color: Colors.white.withOpacity(0.08),
                      image: item.imageUrl != null
                          ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: item.imageUrl == null
                        ? const Center(child: Icon(Icons.photo, color: Colors.white38))
                        : null,
                  ),
                  if ((item.sku ?? '').isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.sku!,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        height: 6,
                        width: 6,
                        decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Stock: ${item.stock}',
                          style: TextStyle(fontSize: 10, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCurrency(item.unitPrice, currency: item.currency),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
