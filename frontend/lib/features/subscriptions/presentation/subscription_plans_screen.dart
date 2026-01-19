import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../../core/formatters.dart';
import '../../users/presentation/users_controller.dart';
import '../data/subscription.dart';
import '../data/subscription_repository.dart';
import 'subscriptions_controller.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  final int? organizationId;
  final String? title;

  const SubscriptionPlansScreen({super.key, this.organizationId, this.title});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final orgId = widget.organizationId;
    final orgSubsAsync = ref.watch(organizationSubscriptionsProvider(orgId));
    final plans = plansAsync.asData?.value ?? const <SubscriptionPlan>[];
    final orgSubs = orgSubsAsync.asData?.value ?? const <OrganizationSubscription>[];
    final current = orgSubs.firstWhere(
      (sub) => sub.status.toLowerCase() == 'active',
      orElse: () => OrganizationSubscription(
        id: 0,
        organizationId: 0,
        subscriptionId: 0,
        status: 'none',
        currency: plans.isNotEmpty ? plans.first.currency : 'USD',
        refundEligible: false,
      ),
    );
    final hasActive = current.id != 0;
    final history = orgSubs.where((sub) => sub.id != current.id).toList();
    final isLoading = plansAsync.isLoading || orgSubsAsync.isLoading || userAsync.isLoading;
    final hasError = plansAsync.hasError || orgSubsAsync.hasError || userAsync.hasError;
    final user = userAsync.asData?.value;
    final screenTitle = widget.title ?? 'My Subscriptions';

    if (orgId != null && user != null && user.role != 'superadmin') {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          title: Text(screenTitle),
        ),
        body: const Center(child: Text('Access denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(screenTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isLoading) const LinearProgressIndicator(),
            if (hasError)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Unable to load subscription data.', style: TextStyle(color: AppColors.textMuted)),
              ),
            const SizedBox(height: 12),
            if (user != null && user.role == 'admin' && (user.email == null || user.email!.isEmpty))
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Add an admin email before changing subscriptions.',
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ),
            const _SectionHeader(title: 'Current Subscription'),
            const SizedBox(height: 8),
            _CurrentSubscriptionCard(subscription: hasActive ? current : null),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: plans.isEmpty ? null : () => _showPlanPicker(context, plans),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: Text(hasActive ? 'Change Plan' : 'Choose Plan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasActive ? () => _cancelSubscription(current) : null,
                    child: const Text('Opt Out'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionHeader(title: 'Subscription History'),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Text('No past subscriptions.', style: TextStyle(color: AppColors.textMuted))
            else
              Column(
                children: history.map((sub) => _HistoryCard(subscription: sub)).toList(),
              ),
            const SizedBox(height: 16),
            const Text(
              'Payments are handled outside the app. Use the superadmin portal to record payments and onboard organizations.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPlanPicker(BuildContext context, List<SubscriptionPlan> plans) async {
    final selected = await showModalBottomSheet<SubscriptionPlan>(
      context: context,
      builder: (context) => _PlanPicker(plans: plans),
    );
    if (selected == null) return;
    await ref
        .read(subscriptionRepositoryProvider)
        .changeOrganizationSubscription(selected.id, organizationId: widget.organizationId);
    ref.invalidate(organizationSubscriptionsProvider(widget.organizationId));
  }

  Future<void> _cancelSubscription(OrganizationSubscription current) async {
    await ref
        .read(subscriptionRepositoryProvider)
        .cancelOrganizationSubscription(current.id, organizationId: widget.organizationId);
    ref.invalidate(organizationSubscriptionsProvider(widget.organizationId));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
    );
  }
}

class _CurrentSubscriptionCard extends StatelessWidget {
  final OrganizationSubscription? subscription;

  const _CurrentSubscriptionCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Text('No active subscription.', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    final plan = subscription!.subscription;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan?.name ?? 'Plan #${subscription!.subscriptionId}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            subscription!.amount == null
                ? 'Custom pricing'
                : formatCurrency(subscription!.amount!, currency: subscription!.currency),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('Status: ${subscription!.status}', style: const TextStyle(color: AppColors.textMuted)),
          if (subscription!.startedAt != null)
            Text('Started: ${formatShortDate(subscription!.startedAt)}', style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final OrganizationSubscription subscription;

  const _HistoryCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final plan = subscription.subscription;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan?.name ?? 'Plan #${subscription.subscriptionId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Status: ${subscription.status}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                if (subscription.startedAt != null)
                  Text('Started: ${formatShortDate(subscription.startedAt)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                if (subscription.endedAt != null)
                  Text('Ended: ${formatShortDate(subscription.endedAt)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (subscription.amount != null)
            Text(
              formatCurrency(subscription.amount!, currency: subscription.currency),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

class _PlanPicker extends StatelessWidget {
  final List<SubscriptionPlan> plans;

  const _PlanPicker({required this.plans});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select a Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return ListTile(
                  title: Text(plan.name),
                  subtitle: Text(plan.description ?? ''),
                  trailing: Text(
                    plan.monthlyPrice == null
                        ? 'Custom'
                        : formatCurrency(plan.monthlyPrice!, currency: plan.currency),
                  ),
                  onTap: () => Navigator.pop(context, plan),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
