import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/formatters.dart';
import '../data/invoice.dart';
import '../data/invoice_repository.dart';
import 'invoices_controller.dart';

class InvoiceDetailsScreen extends ConsumerWidget {
  final int invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceProvider(invoiceId));
    return Scaffold(
      body: invoiceAsync.when(
        data: (invoice) => _InvoiceDetailsBody(invoice: invoice),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _InvoiceDetailsBody extends ConsumerWidget {
  final Invoice invoice;

  const _InvoiceDetailsBody({required this.invoice});

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
                        invoice.invoiceNumber ?? 'Invoice',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatShortDate(invoice.issueDate),
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
                _SectionTitle(title: 'Client'),
                _InfoCard(
                  title: invoice.customerName ?? 'Customer',
                  subtitle: invoice.billingAddress ?? invoice.customerEmail ?? 'No billing details',
                ),
                _SectionTitle(title: 'Invoice Items (${invoice.items.length})'),
                ...invoice.items.map((item) => _InvoiceItemRow(item: item)).toList(),
                _SectionTitle(title: 'Summary'),
                _SummaryCard(invoice: invoice),
              ],
            ),
          ),
          _BottomActions(invoice: invoice),
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

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoCard({required this.title, required this.subtitle});

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
          ],
        ),
      ),
    );
  }
}

class _InvoiceItemRow extends StatelessWidget {
  final InvoiceItem item;

  const _InvoiceItemRow({required this.item});

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
              child: const Icon(Icons.description, color: Colors.white70),
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
  final Invoice invoice;

  const _SummaryCard({required this.invoice});

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
            _SummaryRow(label: 'Tax', value: formatCurrency(invoice.tax, currency: invoice.currency)),
            _SummaryRow(label: 'Discount', value: formatCurrency(invoice.discount, currency: invoice.currency)),
            const Divider(),
            _SummaryRow(
              label: 'Total',
              value: formatCurrency(invoice.totalAmount, currency: invoice.currency),
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
  final Invoice invoice;

  const _BottomActions({required this.invoice});

  Future<void> _updateStatus(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: invoice.status);
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
    final draft = InvoiceDraft(
      status: newStatus,
      issueDate: invoice.issueDate,
      dueDate: invoice.dueDate,
      sourceUrl: invoice.sourceUrl,
      sourceType: invoice.sourceType,
      aiExtracted: invoice.aiExtracted,
      paidAt: invoice.paidAt,
      customerName: invoice.customerName,
      customerEmail: invoice.customerEmail,
      customerPhone: invoice.customerPhone,
      billingAddress: invoice.billingAddress,
      shippingAddress: invoice.shippingAddress,
      notes: invoice.notes,
      tax: invoice.tax,
      discount: invoice.discount,
      currency: invoice.currency,
      organizationId: invoice.organizationId,
      userId: invoice.userId,
      items: invoice.items
          .map((item) => InvoiceLineDraft(
                itemId: item.itemId,
                description: item.description,
                sku: item.sku,
                imageUrl: item.imageUrl,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
              ))
          .toList(),
    );
    await ref.read(invoiceRepositoryProvider).updateInvoice(invoice.id, draft);
    ref.refresh(invoiceProvider(invoice.id));
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
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: () => context.push('/invoices/${invoice.id}/edit'), icon: const Icon(Icons.edit_note)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.print)),
        ],
      ),
    );
  }
}
