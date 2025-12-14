import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceUtils {
  static const _storage = FlutterSecureStorage();
  static const _key = 'device_id';

  static Future<String> getDeviceID() async {
    String? deviceId = await _storage.read(key: _key);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _key, value: deviceId);
    }
    return deviceId;
  }
}
