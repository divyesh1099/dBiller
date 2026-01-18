import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/formatters.dart';
import '../data/order.dart';
import '../data/order_repository.dart';
import 'orders_controller.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));
    return Scaffold(
      body: orderAsync.when(
        data: (order) => _OrderDetailsBody(order: order),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _OrderDetailsBody extends ConsumerWidget {
  final Order order;

  const _OrderDetailsBody({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber ?? 'Order',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatShortDate(order.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                _SectionTitle(title: 'Order Status'),
                _StatusTimeline(order: order),
                _SectionTitle(title: 'Shipping Address'),
                _InfoCard(
                  title: order.customerName ?? 'Customer',
                  subtitle: order.shippingAddress ?? 'No shipping address',
                  action: 'View on map',
                ),
                _SectionTitle(title: 'Order Items (${order.items.length})'),
                ...order.items.map((item) => _OrderItemRow(item: item)).toList(),
                _SectionTitle(title: 'Payment Summary'),
                _SummaryCard(order: order),
              ],
            ),
          ),
          _BottomActions(order: order),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final Order order;

  const _StatusTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepStatus('Created', order.createdAt),
      _StepStatus('Confirmed', order.confirmedAt),
      _StepStatus('Shipped', order.shippedAt),
      _StepStatus('Delivered', order.deliveredAt ?? order.expectedDeliveryAt),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: steps
              .map((step) => ListTile(
                    dense: true,
                    leading: Icon(
                      step.date != null ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: step.date != null ? AppColors.primary : Colors.grey,
                      size: 18,
                    ),
                    title: Text(step.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      step.date != null ? formatShortDate(step.date) : 'Pending',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _StepStatus {
  final String label;
  final DateTime? date;

  _StepStatus(this.label, this.date);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String action;

  const _InfoCard({required this.title, required this.subtitle, required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.map, size: 16),
              label: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.08),
              ),
              child: const Icon(Icons.inventory_2, color: Colors.white70),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.description ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${item.sku ?? '-'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: ${item.quantity}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              formatCurrency(item.lineTotal),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Order order;

  const _SummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            _SummaryRow(label: 'Subtotal', value: formatCurrency(order.subtotal, currency: order.currency)),
            _SummaryRow(label: 'Shipping', value: formatCurrency(order.shippingFee, currency: order.currency)),
            _SummaryRow(label: 'Tax', value: formatCurrency(order.tax, currency: order.currency)),
            const Divider(),
            _SummaryRow(
              label: 'Total',
              value: formatCurrency(order.totalAmount, currency: order.currency),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _BottomActions extends ConsumerWidget {
  final Order order;

  const _BottomActions({required this.order});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: order.status);
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Status'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (newStatus == null || newStatus.isEmpty) return;
    final draft = OrderDraft(
      status: newStatus,
      items: order.items
          .map((item) => OrderLineDraft(
                itemId: item.itemId,
                description: item.description,
                sku: item.sku,
                imageUrl: item.imageUrl,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                aiVerified: item.aiVerified,
                aiConfidence: item.aiConfidence,
              ))
          .toList(),
      orderType: order.orderType,
      supplierId: order.supplierId,
      customerName: order.customerName,
      customerEmail: order.customerEmail,
      customerPhone: order.customerPhone,
      billingAddress: order.billingAddress,
      shippingAddress: order.shippingAddress,
      notes: order.notes,
      shippingFee: order.shippingFee,
      tax: order.tax,
      currency: order.currency,
      organizationId: order.organizationId,
      userId: order.userId,
      confirmedAt: order.confirmedAt,
      shippedAt: order.shippedAt,
      deliveredAt: order.deliveredAt,
      cancelledAt: order.cancelledAt,
      expectedDeliveryAt: order.expectedDeliveryAt,
    );
    await ref.read(orderRepositoryProvider).updateOrder(order.id, draft);
    ref.refresh(orderProvider(order.id));
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
              onPressed: () => _updateStatus(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.edit_note, color: Colors.white),
              label: const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: () {}, icon: const Icon(Icons.print)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.chat)),
        ],
      ),
    );
  }
}
