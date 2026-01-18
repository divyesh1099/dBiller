import 'config.dart';

String? resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  var resolved = url;
  final base = AppConfig.instance.apiBaseUrl;
  if (resolved.contains('http://localhost:8001') && base.contains('10.0.2.2')) {
    resolved = resolved.replaceFirst('http://localhost:8001', 'http://10.0.2.2:8001');
  }
  if (!resolved.startsWith('http')) {
    resolved = '$base$resolved';
  }
  return resolved;
}
