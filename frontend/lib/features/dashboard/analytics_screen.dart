import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../invoices/data/invoice.dart';
import '../invoices/presentation/invoices_controller.dart';
import '../items/data/item.dart';
import '../items/presentation/items_controller.dart';
import '../orders/data/order.dart';
import '../orders/presentation/orders_controller.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final ordersAsync = ref.watch(ordersProvider);
    final itemsAsync = ref.watch(itemsProvider);
    final invoices = invoicesAsync.asData?.value ?? const <Invoice>[];
    final orders = ordersAsync.asData?.value ?? const <Order>[];
    final items = itemsAsync.asData?.value ?? const <Item>[];
    final currency = invoices.isNotEmpty ? invoices.first.currency : 'USD';
    final totalRevenue = invoices
        .where((invoice) => invoice.status.toLowerCase() == 'paid')
        .fold(0.0, (sum, invoice) => sum + invoice.totalAmount);
    final paidInvoices = invoices.where((invoice) => invoice.status.toLowerCase() == 'paid').length;
    final openOrders = orders.where((order) {
      final status = order.status.toLowerCase();
      return status != 'delivered' && status != 'completed' && status != 'cancelled';
    }).length;
    final lowStockItems = items.where(_isLowStock).length;
    final loading = invoicesAsync.isLoading || ordersAsync.isLoading || itemsAsync.isLoading;
    final hasError = invoicesAsync.hasError || ordersAsync.hasError || itemsAsync.hasError;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Sales & Inventory Analytics'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (loading) const LinearProgressIndicator(),
            if (hasError)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Unable to load analytics right now.', style: TextStyle(color: AppColors.textMuted)),
              ),
            const SizedBox(height: 12),
            _MetricCard(
              title: 'Total Revenue',
              value: formatCurrency(totalRevenue, currency: currency),
              helper: '$paidInvoices paid invoices',
            ),
            _MetricCard(
              title: 'Orders',
              value: orders.length.toString(),
              helper: '$openOrders open orders',
            ),
            _MetricCard(
              title: 'Low Stock Items',
              value: lowStockItems.toString(),
              helper: 'Needs replenishment',
            ),
            const SizedBox(height: 12),
            _ChartPlaceholder(title: 'Sales Trend'),
            const SizedBox(height: 12),
            _ChartPlaceholder(title: 'Inventory Turnover'),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String helper;

  const _MetricCard({required this.title, required this.value, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: AppColors.textMuted)),
        subtitle: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        trailing: Text(helper, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

bool _isLowStock(Item item) {
  if (item.minStock != null && item.stock <= item.minStock!) {
    return true;
  }
  if (item.reorderPoint != null && item.stock <= item.reorderPoint!) {
    return true;
  }
  return false;
}

class _ChartPlaceholder extends StatelessWidget {
  final String title;

  const _ChartPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Icon(Icons.show_chart, size: 48, color: Colors.white.withOpacity(0.3)),
            ),
          ),
        ],
      ),
    );
  }
}
