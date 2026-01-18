import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../data/invoice.dart';
import '../data/invoice_repository.dart';
import 'invoices_controller.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final Invoice? initial;

  const InvoiceFormScreen({super.key, this.initial});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _statusController;
  late final TextEditingController _customerController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _billingController;
  late final TextEditingController _taxController;
  late final TextEditingController _discountController;
  bool _saving = false;
  final List<_LineInput> _lines = [];

  @override
  void initState() {
    super.initState();
    final invoice = widget.initial;
    _statusController = TextEditingController(text: invoice?.status ?? 'draft');
    _customerController = TextEditingController(text: invoice?.customerName ?? '');
    _emailController = TextEditingController(text: invoice?.customerEmail ?? '');
    _phoneController = TextEditingController(text: invoice?.customerPhone ?? '');
    _billingController = TextEditingController(text: invoice?.billingAddress ?? '');
    _taxController = TextEditingController(text: invoice?.tax.toString() ?? '0');
    _discountController = TextEditingController(text: invoice?.discount.toString() ?? '0');
    if (invoice != null && invoice.items.isNotEmpty) {
      for (final item in invoice.items) {
        _lines.add(_LineInput.fromInvoiceItem(item));
      }
    } else {
      _lines.add(_LineInput());
    }
  }

  @override
  void dispose() {
    _statusController.dispose();
    _customerController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _billingController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final tax = double.tryParse(_taxController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    final draft = InvoiceDraft(
      status: _statusController.text.isEmpty ? 'draft' : _statusController.text,
      customerName: _customerController.text.isEmpty ? null : _customerController.text,
      customerEmail: _emailController.text.isEmpty ? null : _emailController.text,
      customerPhone: _phoneController.text.isEmpty ? null : _phoneController.text,
      billingAddress: _billingController.text.isEmpty ? null : _billingController.text,
      tax: tax,
      discount: discount,
      currency: widget.initial?.currency ?? 'USD',
      items: _lines.map((e) => e.toDraft()).toList(),
    );
    final repo = ref.read(invoiceRepositoryProvider);
    try {
      if (widget.initial == null) {
        await repo.createInvoice(draft);
      } else {
        await repo.updateInvoice(widget.initial!.id, draft);
      }
      ref.invalidate(invoicesProvider);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addLine() {
    setState(() => _lines.add(_LineInput()));
  }

  void _removeLine(int index) {
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Invoice' : 'New Invoice')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Customer Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Customer Phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _billingController,
                decoration: const InputDecoration(labelText: 'Billing Address'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _taxController,
                      decoration: const InputDecoration(labelText: 'Tax'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(labelText: 'Discount'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Invoice Items', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._lines.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final line = entry.value;
                  return _LineEditor(
                    line: line,
                    onRemove: _lines.length > 1 ? () => _removeLine(index) : null,
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save Invoice' : 'Create Invoice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineInput {
  final TextEditingController description = TextEditingController();
  final TextEditingController sku = TextEditingController();
  final TextEditingController quantity = TextEditingController(text: '1');
  final TextEditingController unitPrice = TextEditingController();

  _LineInput();

  _LineInput.fromInvoiceItem(InvoiceItem item) {
    description.text = item.description ?? '';
    sku.text = item.sku ?? '';
    quantity.text = item.quantity.toString();
    unitPrice.text = item.unitPrice?.toString() ?? '';
  }

  InvoiceLineDraft toDraft() {
    return InvoiceLineDraft(
      description: description.text.isEmpty ? null : description.text,
      sku: sku.text.isEmpty ? null : sku.text,
      quantity: int.tryParse(quantity.text) ?? 1,
      unitPrice: double.tryParse(unitPrice.text),
    );
  }

  void dispose() {
    description.dispose();
    sku.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}

class _LineEditor extends StatelessWidget {
  final _LineInput line;
  final VoidCallback? onRemove;

  const _LineEditor({required this.line, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          TextField(
            controller: line.description,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: line.sku,
                  decoration: const InputDecoration(labelText: 'SKU'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: line.quantity,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: line.unitPrice,
                  decoration: const InputDecoration(labelText: 'Unit Price'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          if (onRemove != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRemove,
                child: const Text('Remove'),
              ),
            ),
        ],
      ),
    );
  }
}
