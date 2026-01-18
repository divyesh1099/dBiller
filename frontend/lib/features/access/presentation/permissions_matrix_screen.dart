import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../data/access_repository.dart';
import '../data/permission.dart';
import '../data/role.dart';
import 'access_controller.dart';

class PermissionsMatrixScreen extends ConsumerStatefulWidget {
  final int roleId;

  const PermissionsMatrixScreen({super.key, required this.roleId});

  @override
  ConsumerState<PermissionsMatrixScreen> createState() => _PermissionsMatrixScreenState();
}

class _PermissionsMatrixScreenState extends ConsumerState<PermissionsMatrixScreen> {
  final Set<int> _selected = {};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(roleProvider(widget.roleId));
    final permissionsAsync = ref.watch(permissionsProvider);

    return Scaffold(
      body: SafeArea(
        child: roleAsync.when(
          data: (role) {
            if (!_initialized) {
              _selected.clear();
              _selected.addAll(role.permissions.map((p) => p.id));
              _initialized = true;
            }
            return Column(
              children: [
                _TopBar(onBack: () => context.canPop() ? context.pop() : context.go('/roles')),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      _RoleHeader(role: role),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Feature Modules',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      permissionsAsync.when(
                        data: (permissions) => _PermissionList(
                          permissions: permissions,
                          selected: _selected,
                          onChanged: (id, value) {
                            setState(() {
                              if (value) {
                                _selected.add(id);
                              } else {
                                _selected.remove(id);
                              }
                            });
                          },
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: LinearProgressIndicator(),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error: $e'),
                        ),
                      ),
                    ],
                  ),
                ),
                _BottomActions(
                  onSave: () async {
                    await ref
                        .read(accessRepositoryProvider)
                        .updateRolePermissions(widget.roleId, _selected.toList());
                    ref.refresh(roleProvider(widget.roleId));
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios)),
          const Expanded(
            child: Text('Permissions Matrix', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline)),
        ],
      ),
    );
  }
}

class _RoleHeader extends StatelessWidget {
  final Role role;

  const _RoleHeader({required this.role});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.manage_accounts, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    role.description ?? 'Role permissions',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionList extends StatelessWidget {
  final List<Permission> permissions;
  final Set<int> selected;
  final void Function(int, bool) onChanged;

  const _PermissionList({
    required this.permissions,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: permissions
          .map(
            (permission) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: SwitchListTile(
                  value: selected.contains(permission.id),
                  onChanged: (value) => onChanged(permission.id, value),
                  title: Text(permission.name),
                  subtitle: permission.description == null
                      ? null
                      : Text(permission.description!, style: const TextStyle(fontSize: 12)),
                  activeColor: AppColors.primary,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final VoidCallback onSave;

  const _BottomActions({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Discard Changes', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
