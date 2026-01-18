import '../../../core/json_utils.dart';

class Permission {
  final int id;
  final String name;
  final String? description;

  Permission({required this.id, required this.name, this.description});

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: readInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
    );
  }
}
