import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../../../../core/device_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.read(apiClientProvider)));

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<String> login(String username, String password) async {
    try {
      final deviceId = await DeviceUtils.getDeviceID();
      final response = await _client.post(
        '/token',
        options: Options(contentType: Headers.formUrlEncodedContentType),
        data: {'username': username, 'password': password, 'device_id': deviceId},
      );
      return response.data['access_token'];
    } on DioException catch (e) {
      if (e.response == null) {
        throw 'Network error: ${e.message}';
      }
      final data = e.response?.data;
      if (data == null) {
        throw 'Server error: ${e.response?.statusCode} ${e.response?.statusMessage}';
      }
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        throw data['detail'];
      }
      throw data.toString();
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> register(
    String username,
    String password,
    String deviceId,
    String licenseKey,
    String email, {
    String? storeName,
    List<int>? logoBytes,
    String? logoName,
  }) async {
    try {
      final form = FormData.fromMap({
        'username': username,
        'password': password,
        'device_id': deviceId,
        'license_key': licenseKey,
        'email': email,
        if (storeName != null && storeName.isNotEmpty) 'store_name': storeName,
        if (logoBytes != null && logoName != null)
          'store_logo': MultipartFile.fromBytes(logoBytes, filename: logoName),
      });
      await _client.post('/register', data: form);
    } on DioException catch (e) {
      if (e.response == null) {
        throw 'Network error: ${e.message}';
      }
      final data = e.response?.data;
      if (data == null) {
        throw 'Server error: ${e.response?.statusCode} ${e.response?.statusMessage}';
      }
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        throw data['detail'];
      }
      throw data.toString();
    } catch (e) {
      throw e.toString();
    }
  }
}
