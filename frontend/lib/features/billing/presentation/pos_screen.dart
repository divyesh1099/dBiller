import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'pos_controller.dart';
import '../../inventory/presentation/inventory_controller.dart';
import '../../inventory/data/product.dart';

class POSScreen extends ConsumerWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final allProductsAsync = ref.watch(productsProvider); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                if (kIsWeb) {
                  final file = await picker.pickImage(source: ImageSource.gallery);
                  if (file != null) notifier.recognizeImage(file);
                } else {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Open Camera'),
                            onTap: () async {
                              Navigator.pop(context);
                              final file = await picker.pickImage(source: ImageSource.camera);
                              if (file != null) notifier.recognizeImage(file);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Upload from Gallery'),
                            onTap: () async {
                              Navigator.pop(context);
                              final file = await picker.pickImage(source: ImageSource.gallery);
                              if (file != null) notifier.recognizeImage(file);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.camera_alt),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              label: const Text('Scan Items'),
            ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          
          final productsView = Column(
            children: [
              // Recognition Results Banner
              if (state.isLoading) const LinearProgressIndicator(),
              if (state.error != null && state.error!.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (state.recognizedProducts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    color: Colors.grey.shade100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Found ${state.recognizedProducts.length} items from image:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                            ),
                            const Spacer(),
                            TextButton(onPressed: () => notifier.clearRecognition(), child: const Text('Clear'))
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: state.recognizedProducts.map((p) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ActionChip(
                                avatar: const Icon(Icons.add, size: 16),
                                label: Text(p.name),
                                onPressed: () => notifier.addToCart(p),
                                backgroundColor: Colors.white,
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

              // Grid
              Expanded(
                child: allProductsAsync.when(
                  data: (products) {
                    final Map<String, List<Product>> byCategory = {};
                    for (final p in products) {
                      final cat = (p.category ?? 'Uncategorized').isNotEmpty ? (p.category ?? 'Uncategorized') : 'Uncategorized';
                      byCategory.putIfAbsent(cat, () => []).add(p);
                    }
                    final entries = byCategory.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      itemBuilder: (context, idx) {
                        final entry = entries[idx];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: entry.value.map((product) {
                                return SizedBox(
                                  width: 160, // Slightly smaller for mobile fit
                                  child: Card(
                                    color: Colors.white,
                                    clipBehavior: Clip.antiAlias,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                    child: InkWell(
                                      onTap: () => notifier.addToCart(product),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          SizedBox(
                                            height: 100,
                                            child: product.imageUrl != null
                                                ? Image.network(
                                                    product.imageUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Container(
                                                      color: Colors.grey[100],
                                                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                                    ),
                                                  )
                                                : Container(
                                                    color: Colors.grey[100],
                                                    child: Icon(Icons.inventory_2, size: 40, color: Colors.grey[400]),
                                                  ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 4),
                                                Text('\$${product.price}', style: const TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          );

          final cartView = Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: const Row(
                    children: [
                       Icon(Icons.shopping_cart_outlined),
                       SizedBox(width: 12),
                       Text('Current Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: state.cart.isEmpty 
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Cart is empty', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ))
                  : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.cart.length,
                    separatorBuilder: (_,__) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = state.cart[index];
                      return Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                            child: Center(child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('\$${item.product.price}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Text('\$${(item.quantity * item.product.price).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                           IconButton(onPressed: () => notifier.removeFromCart(item.product), icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20))
                        ],
                      );
                    },
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                          Text('\$${state.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (0%)', style: TextStyle(color: Colors.grey)),
                          const Text('\$0.00', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('\$${state.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111111))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: state.isLoading || state.cart.isEmpty ? null : () => notifier.checkout("cash"),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.black87,
                           ),
                          child: const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (isMobile) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.black,
                    tabs: [
                      Tab(icon: Icon(Icons.grid_view), text: 'Products'),
                      Tab(icon: Icon(Icons.shopping_cart), text: 'Cart'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        productsView,
                        cartView,
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Row(
              children: [
                Expanded(flex: 3, child: productsView),
                Container(width: 1, color: Colors.grey[300]),
                Expanded(flex: 2, child: cartView),
              ],
            );
          }
        },
      ),
    );
  }
}
