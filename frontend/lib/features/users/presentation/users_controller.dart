import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user.dart';
import '../data/user_repository.dart';

final usersProvider = FutureProvider<List<UserProfile>>((ref) async {
  return ref.read(userRepositoryProvider).fetchUsers();
});

final userProvider = FutureProvider.family<UserProfile, int>((ref, id) async {
  return ref.read(userRepositoryProvider).fetchUser(id);
});
