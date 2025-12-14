import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/config.dart';

class StoreData {
  final int id;
  final String name;
  final String? logoUrl;

  StoreData({required this.id, required this.name, this.logoUrl});

  factory StoreData.fromJson(Map<String, dynamic> json) {
    return StoreData(
      id: json['id'] as int,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
    );
  }
}

final storeRepositoryProvider = Provider((ref) => StoreRepository(ref.read(apiClientProvider)));

class StoreRepository {
  final ApiClient _client;
  StoreRepository(this._client);

  Future<StoreData?> fetchStore() async {
    final res = await _client.get('/store');
    if (res.data == null) return null;
    return _withBaseUrl(StoreData.fromJson(res.data as Map<String, dynamic>));
  }

  Future<StoreData> updateStore({
    String? name,
    List<int>? logoBytes,
    String? logoFilename,
  }) async {
    final form = FormData.fromMap({
      if (name != null) 'name': name,
      if (logoBytes != null && logoFilename != null)
        'logo': MultipartFile.fromBytes(logoBytes, filename: logoFilename),
    });
    final res = await _client.put('/store', data: form);
    return _withBaseUrl(StoreData.fromJson(res.data as Map<String, dynamic>));
  }

  StoreData _withBaseUrl(StoreData s) {
    if (s.logoUrl == null) return s;
    String url = s.logoUrl!;
    final base = AppConfig.instance.apiBaseUrl;

    // Fix legacy localhost URLs on Android
    if (url.contains('http://localhost:8001') && base.contains('10.0.2.2')) {
       url = url.replaceFirst('http://localhost:8001', 'http://10.0.2.2:8001');
    }

    if (!url.startsWith('http')) {
      s = StoreData(id: s.id, name: s.name, logoUrl: '$base$url');
    } else {
       s = StoreData(id: s.id, name: s.name, logoUrl: url);
    }
    return s;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _client.post(
      '/users/change_password',
      data: FormData.fromMap({'old_password': oldPassword, 'new_password': newPassword}),
    );
  }

  Future<void> cancelSubscription() async {
    await _client.post('/subscriptions/cancel');
  }
}
