import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../organizations/data/organization_repository.dart';
import '../subscriptions/presentation/subscriptions_controller.dart';

class SuperadminOnboardScreen extends ConsumerStatefulWidget {
  const SuperadminOnboardScreen({super.key});

  @override
  ConsumerState<SuperadminOnboardScreen> createState() => _SuperadminOnboardScreenState();
}

class _SuperadminOnboardScreenState extends ConsumerState<SuperadminOnboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgController = TextEditingController();
  final _adminUsernameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _amountController = TextEditingController();
  final _paymentRefController = TextEditingController();
  final _notesController = TextEditingController();
  int? _selectedPlanId;
  bool _saving = false;

  @override
  void dispose() {
    _orgController.dispose();
    _adminUsernameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _amountController.dispose();
    _paymentRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final draft = OnboardOrganizationDraft(
        organizationName: _orgController.text,
        adminUsername: _adminUsernameController.text,
        adminPassword: _adminPasswordController.text,
        adminEmail: _adminEmailController.text,
        subscriptionId: _selectedPlanId,
        amount: double.tryParse(_amountController.text),
        paymentReference: _paymentRefController.text.isEmpty ? null : _paymentRefController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      await ref.read(organizationRepositoryProvider).onboardOrganization(draft);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Organization onboarded')));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/superadmin'),
        ),
        title: const Text('Onboard Organization'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _orgController,
                decoration: const InputDecoration(labelText: 'Organization Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminUsernameController,
                decoration: const InputDecoration(labelText: 'Admin Username'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminEmailController,
                decoration: const InputDecoration(labelText: 'Admin Email'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _adminPasswordController,
                decoration: const InputDecoration(labelText: 'Admin Password'),
                obscureText: true,
                validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
              ),
              const SizedBox(height: 12),
              plansAsync.when(
                data: (plans) => DropdownButtonFormField<int?>(
                  value: _selectedPlanId,
                  decoration: const InputDecoration(labelText: 'Subscription Plan'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('No plan')),
                    ...plans.map(
                      (plan) => DropdownMenuItem<int?>(
                        value: plan.id,
                        child: Text(plan.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedPlanId = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading plans: $e'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Payment Amount (optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paymentRefController,
                decoration: const InputDecoration(labelText: 'Payment Reference (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
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
                      : const Text('Onboard Organization'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
