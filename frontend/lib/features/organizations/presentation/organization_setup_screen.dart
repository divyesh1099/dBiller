import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../data/organization.dart';
import '../data/organization_repository.dart';
import 'organizations_controller.dart';

class OrganizationSetupScreen extends ConsumerStatefulWidget {
  final Organization? initial;

  const OrganizationSetupScreen({super.key, this.initial});

  @override
  ConsumerState<OrganizationSetupScreen> createState() => _OrganizationSetupScreenState();
}

class _OrganizationSetupScreenState extends ConsumerState<OrganizationSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _businessController;
  late final TextEditingController _taxController;
  late final TextEditingController _logoController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final org = widget.initial;
    _nameController = TextEditingController(text: org?.name ?? '');
    _companyController = TextEditingController(text: org?.companyName ?? '');
    _businessController = TextEditingController(text: org?.businessType ?? '');
    _taxController = TextEditingController(text: org?.taxId ?? '');
    _logoController = TextEditingController(text: org?.logoUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _businessController.dispose();
    _taxController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final draft = OrganizationDraft(
      name: _nameController.text,
      companyName: _companyController.text.isEmpty ? null : _companyController.text,
      businessType: _businessController.text.isEmpty ? null : _businessController.text,
      taxId: _taxController.text.isEmpty ? null : _taxController.text,
      logoUrl: _logoController.text.isEmpty ? null : _logoController.text,
      status: widget.initial?.status ?? 'active',
      subscriptionId: widget.initial?.subscriptionId,
      nodeLimit: widget.initial?.nodeLimit,
    );
    final repo = ref.read(organizationRepositoryProvider);
    try {
      if (widget.initial == null) {
        await repo.createOrganization(draft);
      } else {
        await repo.updateOrganization(widget.initial!.id, draft);
      }
      ref.invalidate(organizationsProvider);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Organization' : 'Organization Setup')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.12), style: BorderStyle.solid),
                  color: Colors.white.withOpacity(0.04),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: const Icon(Icons.add_a_photo, color: AppColors.primary),
                    ),
                    const SizedBox(height: 10),
                    const Text('Upload Logo', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _logoController,
                      decoration: const InputDecoration(labelText: 'Logo URL'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Organization Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _businessController,
                decoration: const InputDecoration(labelText: 'Business Type'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxController,
                decoration: const InputDecoration(labelText: 'Tax ID'),
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
                      : Text(isEdit ? 'Save Organization' : 'Complete Setup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
