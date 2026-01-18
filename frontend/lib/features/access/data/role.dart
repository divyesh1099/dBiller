import '../../../core/json_utils.dart';
import 'permission.dart';

class Role {
  final int id;
  final String name;
  final String? description;
  final List<Permission> permissions;

  Role({
    required this.id,
    required this.name,
    this.description,
    this.permissions = const [],
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: readInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => Permission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
