import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../data/supplier.dart';
import '../data/supplier_repository.dart';
import 'suppliers_controller.dart';

class SupplierFormScreen extends ConsumerStatefulWidget {
  final Supplier? initial;

  const SupplierFormScreen({super.key, this.initial});

  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _categoryController;
  late final TextEditingController _codeController;
  late final TextEditingController _logoController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final supplier = widget.initial;
    _nameController = TextEditingController(text: supplier?.name ?? '');
    _companyController = TextEditingController(text: supplier?.companyName ?? '');
    _contactController = TextEditingController(text: supplier?.contactName ?? '');
    _emailController = TextEditingController(text: supplier?.email ?? '');
    _phoneController = TextEditingController(text: supplier?.phone ?? '');
    _addressController = TextEditingController(text: supplier?.address ?? '');
    _categoryController = TextEditingController(text: supplier?.category ?? '');
    _codeController = TextEditingController(text: supplier?.supplierCode ?? '');
    _logoController = TextEditingController(text: supplier?.logoUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    _codeController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final draft = SupplierDraft(
      name: _nameController.text,
      companyName: _companyController.text.isEmpty ? null : _companyController.text,
      contactName: _contactController.text.isEmpty ? null : _contactController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      category: _categoryController.text.isEmpty ? null : _categoryController.text,
      supplierCode: _codeController.text.isEmpty ? null : _codeController.text,
      logoUrl: _logoController.text.isEmpty ? null : _logoController.text,
      status: widget.initial?.status ?? 'active',
    );
    final repo = ref.read(supplierRepositoryProvider);
    try {
      if (widget.initial == null) {
        await repo.createSupplier(draft);
      } else {
        await repo.updateSupplier(widget.initial!.id, draft);
      }
      ref.invalidate(suppliersProvider);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Supplier' : 'New Supplier')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Supplier Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Supplier Code'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _logoController,
                decoration: const InputDecoration(labelText: 'Logo URL'),
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
                      : Text(isEdit ? 'Save Supplier' : 'Create Supplier'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
