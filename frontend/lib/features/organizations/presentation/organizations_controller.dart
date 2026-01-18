import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/organization.dart';
import '../data/organization_repository.dart';

final organizationsProvider = FutureProvider<List<Organization>>((ref) async {
  return ref.read(organizationRepositoryProvider).fetchOrganizations();
});

final organizationProvider = FutureProvider.family<Organization, int>((ref, id) async {
  return ref.read(organizationRepositoryProvider).fetchOrganization(id);
});
