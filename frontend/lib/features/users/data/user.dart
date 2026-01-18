import '../../../core/json_utils.dart';
import '../../../core/url_utils.dart';

class UserRole {
  final int id;
  final String name;
  final String? description;

  UserRole({required this.id, required this.name, this.description});

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: readInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
    );
  }
}

class UserPermission {
  final int id;
  final String name;
  final String? description;

  UserPermission({required this.id, required this.name, this.description});

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      id: readInt(json['id']),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
    );
  }
}

class UserProfile {
  final int id;
  final String username;
  final String? fullName;
  final String? userCode;
  final String? email;
  final String? phone;
  final String role;
  final bool activeAccount;
  final String? profilePhoto;
  final int? organizationId;
  final List<UserRole> roles;
  final List<UserPermission> permissions;

  UserProfile({
    required this.id,
    required this.username,
    required this.role,
    required this.activeAccount,
    this.fullName,
    this.userCode,
    this.email,
    this.phone,
    this.profilePhoto,
    this.organizationId,
    this.roles = const [],
    this.permissions = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: readInt(json['id']),
      username: (json['username'] ?? '').toString(),
      fullName: json['full_name'] as String?,
      userCode: json['user_code'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: (json['role'] ?? 'staff').toString(),
      activeAccount: readBool(json['active_account'], fallback: true),
      profilePhoto: resolveMediaUrl(json['profile_photo'] as String?),
      organizationId: json['organization_id'] == null ? null : readInt(json['organization_id']),
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => UserRole.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => UserPermission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
