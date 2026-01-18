import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../data/order.dart';
import '../data/order_repository.dart';
import 'orders_controller.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  final Order? initial;

  const OrderFormScreen({super.key, this.initial});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _statusController;
  late final TextEditingController _typeController;
  late final TextEditingController _customerController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _shippingController;
  late final TextEditingController _taxController;
  late final TextEditingController _shippingFeeController;
  bool _saving = false;
  final List<_LineInput> _lines = [];

  @override
  void initState() {
    super.initState();
    final order = widget.initial;
    _statusController = TextEditingController(text: order?.status ?? 'pending');
    _typeController = TextEditingController(text: order?.orderType ?? '');
    _customerController = TextEditingController(text: order?.customerName ?? '');
    _emailController = TextEditingController(text: order?.customerEmail ?? '');
    _phoneController = TextEditingController(text: order?.customerPhone ?? '');
    _shippingController = TextEditingController(text: order?.shippingAddress ?? '');
    _taxController = TextEditingController(text: order?.tax.toString() ?? '0');
    _shippingFeeController = TextEditingController(text: order?.shippingFee.toString() ?? '0');
    if (order != null && order.items.isNotEmpty) {
      for (final item in order.items) {
        _lines.add(_LineInput.fromOrderItem(item));
      }
    } else {
      _lines.add(_LineInput());
    }
  }

  @override
  void dispose() {
    _statusController.dispose();
    _typeController.dispose();
    _customerController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _shippingController.dispose();
    _taxController.dispose();
    _shippingFeeController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final tax = double.tryParse(_taxController.text) ?? 0;
    final shippingFee = double.tryParse(_shippingFeeController.text) ?? 0;
    final items = _lines.map((line) => line.toDraft()).toList();
    final draft = OrderDraft(
      status: _statusController.text.isEmpty ? 'pending' : _statusController.text,
      orderType: _typeController.text.isEmpty ? null : _typeController.text,
      customerName: _customerController.text.isEmpty ? null : _customerController.text,
      customerEmail: _emailController.text.isEmpty ? null : _emailController.text,
      customerPhone: _phoneController.text.isEmpty ? null : _phoneController.text,
      shippingAddress: _shippingController.text.isEmpty ? null : _shippingController.text,
      tax: tax,
      shippingFee: shippingFee,
      currency: widget.initial?.currency ?? 'USD',
      items: items,
    );
    final repo = ref.read(orderRepositoryProvider);
    try {
      if (widget.initial == null) {
        await repo.createOrder(draft);
      } else {
        await repo.updateOrder(widget.initial!.id, draft);
      }
      ref.invalidate(ordersProvider);
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
      appBar: AppBar(title: Text(isEdit ? 'Edit Order' : 'New Order')),
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
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Order Type'),
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
                controller: _shippingController,
                decoration: const InputDecoration(labelText: 'Shipping Address'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _shippingFeeController,
                      decoration: const InputDecoration(labelText: 'Shipping Fee'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _taxController,
                      decoration: const InputDecoration(labelText: 'Tax'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      : Text(isEdit ? 'Save Order' : 'Create Order'),
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

  _LineInput.fromOrderItem(OrderItem item) {
    description.text = item.description ?? '';
    sku.text = item.sku ?? '';
    quantity.text = item.quantity.toString();
    unitPrice.text = item.unitPrice?.toString() ?? '';
  }

  OrderLineDraft toDraft() {
    return OrderLineDraft(
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
