import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../data/access_repository.dart';
import '../data/role.dart';
import 'access_controller.dart';

class RolesManagementScreen extends ConsumerWidget {
  const RolesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onBack: () => context.canPop() ? context.pop() : context.go('/home'),
              onAdd: () => _showCreateRole(context, ref),
            ),
            Expanded(
              child: rolesAsync.when(
                data: (roles) {
                  if (roles.isEmpty) {
                    return const Center(child: Text('No roles created.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: roles.length,
                    itemBuilder: (context, index) {
                      final role = roles[index];
                      return _RoleCard(role: role, onTap: () => context.push('/roles/${role.id}'));
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _showCreateRole(context, ref),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Create New Role', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _showCreateRole(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Role Name')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    if (created != true || nameController.text.isEmpty) return;
    await ref.read(accessRepositoryProvider).createRole(
          RoleDraft(name: nameController.text, description: descController.text.isEmpty ? null : descController.text),
        );
    ref.invalidate(rolesProvider);
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onAdd;

  const _TopBar({required this.onBack, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios)),
          const Expanded(
            child: Text('Roles Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle_outline)),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Role role;
  final VoidCallback onTap;

  const _RoleCard({required this.role, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                role.description ?? 'No description',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${role.permissions.length} permissions', style: const TextStyle(fontSize: 12)),
                  const Icon(Icons.edit, color: AppColors.primary, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
