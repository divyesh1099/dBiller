import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../../access/presentation/access_controller.dart';
import '../data/user.dart';
import '../data/user_repository.dart';
import 'users_controller.dart';

class UserDetailsScreen extends ConsumerStatefulWidget {
  final int userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _roleController;
  bool _active = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _roleController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _bindOnce(UserProfile user) {
    if (_initialized) return;
    _fullNameController.text = user.fullName ?? '';
    _emailController.text = user.email ?? '';
    _phoneController.text = user.phone ?? '';
    _roleController.text = user.role;
    _active = user.activeAccount;
    _initialized = true;
  }

  Future<void> _save(UserProfile user) async {
    if (!_formKey.currentState!.validate()) return;
    final draft = UserDraft(
      username: user.username,
      fullName: _fullNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      role: _roleController.text.isEmpty ? user.role : _roleController.text,
      activeAccount: _active,
      profilePhoto: user.profilePhoto,
      organizationId: user.organizationId,
      roleIds: user.roles.map((r) => r.id).toList(),
      permissionIds: user.permissions.map((p) => p.id).toList(),
    );
    await ref.read(userRepositoryProvider).updateUser(user.id, draft);
    ref.invalidate(usersProvider);
    if (mounted) context.pop();
  }

  Future<void> _delete(UserProfile user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(userRepositoryProvider).deleteUser(user.id);
    ref.invalidate(usersProvider);
    if (mounted) context.pop();
  }

  Future<void> _editRoles(UserProfile user) async {
    final rolesAsync = await ref.read(rolesProvider.future);
    final selected = user.roles.map((r) => r.id).toSet();
    final updated = await showModalBottomSheet<Set<int>>(
      context: context,
      builder: (context) {
        return _SelectionSheet(
          title: 'Select Roles',
          options: rolesAsync.map((r) => _Option(id: r.id, label: r.name)).toList(),
          initial: selected,
        );
      },
    );
    if (updated == null) return;
    await ref.read(userRepositoryProvider).updateUserRoles(user.id, updated.toList());
    ref.refresh(userProvider(user.id));
  }

  Future<void> _editPermissions(UserProfile user) async {
    final permissionsAsync = await ref.read(permissionsProvider.future);
    final selected = user.permissions.map((p) => p.id).toSet();
    final updated = await showModalBottomSheet<Set<int>>(
      context: context,
      builder: (context) {
        return _SelectionSheet(
          title: 'Select Permissions',
          options: permissionsAsync.map((p) => _Option(id: p.id, label: p.name)).toList(),
          initial: selected,
        );
      },
    );
    if (updated == null) return;
    await ref.read(userRepositoryProvider).updateUserPermissions(user.id, updated.toList());
    ref.refresh(userProvider(user.id));
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider(widget.userId));
    return Scaffold(
      body: userAsync.when(
        data: (user) {
          _bindOnce(user);
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.pop(),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back_ios, size: 18),
                            SizedBox(width: 6),
                            Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text('Edit User', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _save(user),
                        child: const Text('Save', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 90),
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            backgroundImage: user.profilePhoto != null
                                ? NetworkImage(user.profilePhoto!)
                                : null,
                            child: user.profilePhoto == null
                                ? Text(
                                    user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            user.fullName ?? user.username,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(title: 'Personal Information'),
                        _InputCard(
                          child: Column(
                            children: [
                              _InputField(label: 'Full Name', controller: _fullNameController),
                              _InputField(label: 'Email Address', controller: _emailController),
                              _InputField(label: 'Phone Number', controller: _phoneController),
                            ],
                          ),
                        ),
                        _SectionHeader(title: 'Role & Permissions'),
                        _InputCard(
                          child: Column(
                            children: [
                              _TapRow(
                                title: 'Account Role',
                                value: _roleController.text,
                                onTap: () => _editRoles(user),
                              ),
                              const Divider(height: 1),
                              _TapRow(
                                title: 'Permissions',
                                value: '${user.permissions.length} selected',
                                onTap: () => _editPermissions(user),
                              ),
                            ],
                          ),
                        ),
                        _SectionHeader(title: 'Account Status'),
                        _InputCard(
                          child: SwitchListTile(
                            value: _active,
                            onChanged: (value) => setState(() => _active = value),
                            title: const Text('Active Account'),
                            activeColor: AppColors.primary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => _save(user),
                            child: const Text('Save Changes'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: OutlinedButton.icon(
                            onPressed: () => _delete(user),
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            label: const Text('Delete User', style: TextStyle(color: Colors.redAccent)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;

  const _InputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: child,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _InputField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _TapRow({required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: AppColors.primary)),
          const SizedBox(width: 6),
          const Icon(Icons.expand_more),
        ],
      ),
    );
  }
}

class _Option {
  final int id;
  final String label;

  _Option({required this.id, required this.label});
}

class _SelectionSheet extends StatefulWidget {
  final String title;
  final List<_Option> options;
  final Set<int> initial;

  const _SelectionSheet({
    required this.title,
    required this.options,
    required this.initial,
  });

  @override
  State<_SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<_SelectionSheet> {
  late Set<int> selected;

  @override
  void initState() {
    super.initState();
    selected = {...widget.initial};
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: widget.options
                  .map(
                    (option) => CheckboxListTile(
                      title: Text(option.label),
                      value: selected.contains(option.id),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selected.add(option.id);
                          } else {
                            selected.remove(option.id);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
