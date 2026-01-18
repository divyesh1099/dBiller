import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/formatters.dart';
import '../data/subscription.dart';
import 'subscriptions_controller.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  String _billingCycle = 'monthly';

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Subscription Plans'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _BillingToggle(
              selected: _billingCycle,
              onChanged: (value) => setState(() => _billingCycle = value),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the plan that fits your business needs',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: plansAsync.when(
                data: (plans) {
                  if (plans.isEmpty) {
                    return const Center(child: Text('No subscription plans available.'));
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      final price = _billingCycle == 'monthly' ? plan.monthlyPrice : plan.annualPrice;
                      return _PlanCard(
                        plan: plan,
                        price: price,
                        billingCycle: _billingCycle,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemCount: plans.length,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _BillingToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ToggleButton(
                label: 'Monthly',
                selected: selected == 'monthly',
                onTap: () => onChanged('monthly'),
              ),
            ),
            Expanded(
              child: _ToggleButton(
                label: 'Yearly',
                selected: selected == 'yearly',
                onTap: () => onChanged('yearly'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? AppColors.textDark : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final double? price;
  final String billingCycle;

  const _PlanCard({
    required this.plan,
    required this.price,
    required this.billingCycle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: plan.isFeatured ? AppColors.primary : Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.badgeText != null && plan.badgeText!.isNotEmpty)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  plan.badgeText!,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          Text(plan.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            price == null ? 'Custom' : '${formatCurrency(price!, currency: plan.currency)} / $billingCycle',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(plan.description ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: plan.features
                  .map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(feature, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.isFeatured ? AppColors.primary : Colors.white.withOpacity(0.1),
              ),
              onPressed: () {},
              child: Text(plan.isFeatured ? 'Choose Plan' : 'Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}
