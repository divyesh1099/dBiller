import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../organizations/presentation/organizations_controller.dart';
import '../subscriptions/presentation/subscriptions_controller.dart';
import '../users/presentation/users_controller.dart';

class SuperadminDashboardScreen extends ConsumerWidget {
  const SuperadminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final orgsAsync = ref.watch(organizationsProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return userAsync.when(
      data: (user) {
        if (user.role != 'superadmin') {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
              ),
              title: const Text('Superadmin Dashboard'),
            ),
            body: const Center(child: Text('Access denied')),
          );
        }

        final orgs = orgsAsync.asData?.value ?? const [];
        final plans = plansAsync.asData?.value ?? const [];
        final planById = {for (final plan in plans) plan.id: plan};
        final activeSubscriptions = orgs.where((org) => org.subscriptionId != null).length;
        double mrr = 0;
        for (final org in orgs) {
          final planId = org.subscriptionId;
          if (planId == null) continue;
          final plan = planById[planId];
          if (plan == null) continue;
          mrr += plan.monthlyPrice ?? plan.price ?? 0;
        }
        final currency = plans.isNotEmpty ? plans.first.currency : 'USD';
        final loading = orgsAsync.isLoading || plansAsync.isLoading;
        final hasError = orgsAsync.hasError || plansAsync.hasError;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            ),
            title: const Text('Superadmin Dashboard'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (loading) const LinearProgressIndicator(),
                if (hasError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Unable to load superadmin stats.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                const SizedBox(height: 12),
                _MetricTile(title: 'Organizations', value: orgs.length.toString()),
                _MetricTile(title: 'Active Subscriptions', value: activeSubscriptions.toString()),
                _MetricTile(title: 'MRR', value: formatCurrency(mrr, currency: currency)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('System Health', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.82,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      const Text('82% uptime this month', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;

  const _MetricTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: AppColors.textMuted)),
        trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
