import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../data/item.dart';
import '../data/item_repository.dart';
import 'items_controller.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  final Item? initial;

  const ItemFormScreen({super.key, this.initial});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _reorderController;
  late final TextEditingController _descriptionController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _nameController = TextEditingController(text: item?.name ?? '');
    _skuController = TextEditingController(text: item?.sku ?? '');
    _categoryController = TextEditingController(text: item?.category ?? '');
    _priceController = TextEditingController(text: item?.unitPrice.toString() ?? '');
    _stockController = TextEditingController(text: item?.stock.toString() ?? '');
    _imageController = TextEditingController(text: item?.imageUrl ?? '');
    _barcodeController = TextEditingController(text: item?.barcode ?? '');
    _reorderController = TextEditingController(text: item?.reorderPoint?.toString() ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    _barcodeController.dispose();
    _reorderController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final price = double.tryParse(_priceController.text) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final reorder = int.tryParse(_reorderController.text);
    final draft = ItemDraft(
      name: _nameController.text,
      unitPrice: price,
      stock: stock,
      sku: _skuController.text.isEmpty ? null : _skuController.text,
      category: _categoryController.text.isEmpty ? null : _categoryController.text,
      imageUrl: _imageController.text.isEmpty ? null : _imageController.text,
      barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
      reorderPoint: reorder,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      currency: widget.initial?.currency ?? 'USD',
    );
    final repo = ref.read(itemRepositoryProvider);
    try {
      if (widget.initial == null) {
        await repo.createItem(draft);
      } else {
        await repo.updateItem(widget.initial!.id, draft);
      }
      ref.invalidate(itemsProvider);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Item' : 'New Item'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(labelText: 'SKU'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Unit Price'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(labelText: 'Barcode'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reorderController,
                      decoration: const InputDecoration(labelText: 'Reorder Point'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Create Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
