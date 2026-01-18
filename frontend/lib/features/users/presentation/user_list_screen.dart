import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../data/user.dart';
import 'users_controller.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final _searchController = TextEditingController();
  String _roleFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onBack: () => context.pop()),
            _SearchBar(controller: _searchController, onChanged: (_) => setState(() {})),
            _RoleChips(selected: _roleFilter, onSelected: (role) => setState(() => _roleFilter = role)),
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  final query = _searchController.text.toLowerCase();
                  final filtered = users.where((user) {
                    final matchesQuery = user.username.toLowerCase().contains(query) ||
                        (user.email ?? '').toLowerCase().contains(query) ||
                        (user.fullName ?? '').toLowerCase().contains(query);
                    final matchesRole = _roleFilter == 'All' || user.role.toLowerCase() == _roleFilter.toLowerCase();
                    return matchesQuery && matchesRole;
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      return _UserRow(user: user, onTap: () => context.push('/users/${user.id}'));
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: () => context.push('/users/new'),
          label: const Text('Add New User', style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.person_add, color: Colors.white),
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
            child: Column(
              children: [
                Text('User Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Organization: dBiller', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name, email, or role',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _RoleChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _RoleChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final roles = ['All', 'admin', 'manager', 'staff'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final role = roles[index];
          final isSelected = role == selected;
          return ChoiceChip(
            label: Text(role == 'All' ? 'All' : role[0].toUpperCase() + role.substring(1)),
            selected: isSelected,
            onSelected: (_) => onSelected(role),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white.withOpacity(0.08),
            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: roles.length,
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onTap;

  const _UserRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final role = user.role.isEmpty ? 'staff' : user.role;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.1),
                backgroundImage: user.profilePhoto != null ? NetworkImage(user.profilePhoto!) : null,
                child: user.profilePhoto == null
                    ? Text(
                        user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName ?? user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(user.email ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
