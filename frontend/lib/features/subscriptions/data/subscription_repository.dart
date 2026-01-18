import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'subscription.dart';

final subscriptionRepositoryProvider = Provider((ref) => SubscriptionRepository(ref.read(apiClientProvider)));

class SubscriptionDraft {
  final String name;
  final double? price;
  final String currency;
  final double? monthlyPrice;
  final double? annualPrice;
  final List<String> features;
  final Map<String, dynamic> limits;
  final String? description;
  final String? badgeText;
  final bool isFeatured;
  final bool isActive;

  SubscriptionDraft({
    required this.name,
    this.price,
    this.currency = 'USD',
    this.monthlyPrice,
    this.annualPrice,
    this.features = const [],
    this.limits = const {},
    this.description,
    this.badgeText,
    this.isFeatured = false,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (price != null) 'price': price,
      'currency': currency,
      if (monthlyPrice != null) 'monthly_price': monthlyPrice,
      if (annualPrice != null) 'annual_price': annualPrice,
      if (features.isNotEmpty) 'features': features,
      if (limits.isNotEmpty) 'limits': limits,
      if (description != null) 'description': description,
      if (badgeText != null) 'badge_text': badgeText,
      'is_featured': isFeatured,
      'is_active': isActive,
    };
  }
}

class SubscriptionRepository {
  final ApiClient _client;

  SubscriptionRepository(this._client);

  Future<List<SubscriptionPlan>> fetchPlans() async {
    final response = await _client.get('/subscriptions/');
    return (response.data as List)
        .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionPlan> fetchPlan(int id) async {
    final response = await _client.get('/subscriptions/$id');
    return SubscriptionPlan.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubscriptionPlan> createPlan(SubscriptionDraft draft) async {
    final response = await _client.post('/subscriptions/', data: draft.toJson());
    return SubscriptionPlan.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubscriptionPlan> updatePlan(int id, SubscriptionDraft draft) async {
    final response = await _client.put('/subscriptions/$id', data: draft.toJson());
    return SubscriptionPlan.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePlan(int id) async {
    await _client.delete('/subscriptions/$id');
  }
}
