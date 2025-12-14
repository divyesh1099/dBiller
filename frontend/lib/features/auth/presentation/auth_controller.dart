import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/auth_repository.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._repository) : super(const AsyncData(null));

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    try {
      final token = await _repository.login(username, password);
      await _storage.write(key: 'access_token', value: token);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  
  Future<void> register(String username, String password, String deviceId, String licenseKey, {String? storeName, List<int>? logoBytes, String? logoName}) async {
    await _repository.register(username, password, deviceId, licenseKey, storeName: storeName, logoBytes: logoBytes, logoName: logoName);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    // In a real app, we might want to refresh the router or state here
  }
}
