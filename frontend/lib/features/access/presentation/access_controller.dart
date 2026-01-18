import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/access_repository.dart';
import '../data/role.dart';
import '../data/permission.dart';

final rolesProvider = FutureProvider<List<Role>>((ref) async {
  return ref.read(accessRepositoryProvider).fetchRoles();
});

final permissionsProvider = FutureProvider<List<Permission>>((ref) async {
  return ref.read(accessRepositoryProvider).fetchPermissions();
});

final roleProvider = FutureProvider.family<Role, int>((ref, id) async {
  return ref.read(accessRepositoryProvider).fetchRole(id);
});
