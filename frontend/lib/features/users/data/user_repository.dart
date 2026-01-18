import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import 'user.dart';

final userRepositoryProvider = Provider((ref) => UserRepository(ref.read(apiClientProvider)));

class UserDraft {
  final String username;
  final String? fullName;
  final String? userCode;
  final String? email;
  final String? phone;
  final String role;
  final bool activeAccount;
  final String? profilePhoto;
  final int? organizationId;
  final String? password;
  final List<int> roleIds;
  final List<int> permissionIds;

  UserDraft({
    required this.username,
    this.fullName,
    this.userCode,
    this.email,
    this.phone,
    this.role = 'staff',
    this.activeAccount = true,
    this.profilePhoto,
    this.organizationId,
    this.password,
    this.roleIds = const [],
    this.permissionIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      if (fullName != null) 'full_name': fullName,
      if (userCode != null) 'user_code': userCode,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'role': role,
      'active_account': activeAccount,
      if (profilePhoto != null) 'profile_photo': profilePhoto,
      if (organizationId != null) 'organization_id': organizationId,
      if (password != null) 'password': password,
      if (roleIds.isNotEmpty) 'role_ids': roleIds,
      if (permissionIds.isNotEmpty) 'permission_ids': permissionIds,
    };
  }
}

class UserRepository {
  final ApiClient _client;

  UserRepository(this._client);

  Future<List<UserProfile>> fetchUsers() async {
    final response = await _client.get('/users/');
    return (response.data as List)
        .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfile> fetchUser(int id) async {
    final response = await _client.get('/users/$id');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> createUser(UserDraft draft) async {
    final response = await _client.post('/users/', data: draft.toJson());
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateUser(int id, UserDraft draft) async {
    final response = await _client.put('/users/$id', data: draft.toJson());
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateUserRoles(int id, List<int> roleIds) async {
    final response = await _client.put('/users/$id/roles', data: {'role_ids': roleIds});
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateUserPermissions(int id, List<int> permissionIds) async {
    final response =
        await _client.put('/users/$id/permissions', data: {'permission_ids': permissionIds});
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteUser(int id) async {
    await _client.delete('/users/$id');
  }
}
