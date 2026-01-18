import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/formatters.dart';
import '../data/subscription.dart';
import '../data/subscription_repository.dart';
import 'subscriptions_controller.dart';

class PlanManagerScreen extends ConsumerWidget {
  const PlanManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Plan Manager'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: plansAsync.when(
                data: (plans) {
                  if (plans.isEmpty) {
                    return const Center(child: Text('No plans available.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return _PlanCard(plan: plan);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showCreatePlan(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showCreatePlan(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final monthlyController = TextEditingController();
    final yearlyController = TextEditingController();
    final descController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: monthlyController, decoration: const InputDecoration(labelText: 'Monthly Price')),
            TextField(controller: yearlyController, decoration: const InputDecoration(labelText: 'Annual Price')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    if (created != true || nameController.text.isEmpty) return;
    final draft = SubscriptionDraft(
      name: nameController.text,
      monthlyPrice: double.tryParse(monthlyController.text),
      annualPrice: double.tryParse(yearlyController.text),
      description: descController.text.isEmpty ? null : descController.text,
    );
    await ref.read(subscriptionRepositoryProvider).createPlan(draft);
    ref.invalidate(subscriptionPlansProvider);
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: plan.isFeatured ? AppColors.primary : Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(plan.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (plan.isFeatured)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Popular', style: TextStyle(fontSize: 9, color: AppColors.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.monthlyPrice == null
                  ? 'Custom'
                  : '${formatCurrency(plan.monthlyPrice!, currency: plan.currency)} / mo',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(plan.description ?? 'No description', style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: plan.features
                  .map(
                    (feature) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(feature, style: const TextStyle(fontSize: 10)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Edit Plan'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
