import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'permission.dart';
import 'role.dart';

final accessRepositoryProvider = Provider((ref) => AccessRepository(ref.read(apiClientProvider)));

class RoleDraft {
  final String name;
  final String? description;

  RoleDraft({required this.name, this.description});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
    };
  }
}

class PermissionDraft {
  final String name;
  final String? description;

  PermissionDraft({required this.name, this.description});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
    };
  }
}

class AccessRepository {
  final ApiClient _client;

  AccessRepository(this._client);

  Future<List<Role>> fetchRoles() async {
    final response = await _client.get('/roles/');
    return (response.data as List)
        .map((e) => Role.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Role> fetchRole(int id) async {
    final response = await _client.get('/roles/$id');
    return Role.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Role> createRole(RoleDraft draft) async {
    final response = await _client.post('/roles/', data: draft.toJson());
    return Role.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Role> updateRole(int id, RoleDraft draft) async {
    final response = await _client.put('/roles/$id', data: draft.toJson());
    return Role.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Role> updateRolePermissions(int id, List<int> permissionIds) async {
    final response =
        await _client.put('/roles/$id/permissions', data: {'permission_ids': permissionIds});
    return Role.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRole(int id) async {
    await _client.delete('/roles/$id');
  }

  Future<List<Permission>> fetchPermissions() async {
    final response = await _client.get('/permissions/');
    return (response.data as List)
        .map((e) => Permission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Permission> createPermission(PermissionDraft draft) async {
    final response = await _client.post('/permissions/', data: draft.toJson());
    return Permission.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Permission> updatePermission(int id, PermissionDraft draft) async {
    final response = await _client.put('/permissions/$id', data: draft.toJson());
    return Permission.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePermission(int id) async {
    await _client.delete('/permissions/$id');
  }
}
