import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/subscription.dart';
import '../data/subscription_repository.dart';

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  return ref.read(subscriptionRepositoryProvider).fetchPlans();
});

final organizationSubscriptionsProvider =
    FutureProvider.family<List<OrganizationSubscription>, int?>((ref, organizationId) async {
  return ref.read(subscriptionRepositoryProvider).fetchOrganizationSubscriptions(organizationId: organizationId);
});
