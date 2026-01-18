import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import '../data/organization.dart';
import 'organizations_controller.dart';

class OrganizationManagementScreen extends ConsumerStatefulWidget {
  const OrganizationManagementScreen({super.key});

  @override
  ConsumerState<OrganizationManagementScreen> createState() => _OrganizationManagementScreenState();
}

class _OrganizationManagementScreenState extends ConsumerState<OrganizationManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organizationsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onAdd: () => context.push('/organizations/new')),
            _SearchBar(controller: _searchController, onChanged: (_) => setState(() {})),
            Expanded(
              child: orgsAsync.when(
                data: (orgs) {
                  final query = _searchController.text.toLowerCase();
                  final filtered = orgs.where((org) {
                    return org.name.toLowerCase().contains(query) ||
                        (org.companyName ?? '').toLowerCase().contains(query);
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No organizations found.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final org = filtered[index];
                      return _OrgCard(org: org, onTap: () => context.push('/organizations/${org.id}'));
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/organizations/new'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onAdd;

  const _TopBar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          const Icon(Icons.dashboard_customize, color: AppColors.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Organizations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle_outline)),
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
          hintText: 'Search organizations...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  final Organization org;
  final VoidCallback onTap;

  const _OrgCard({required this.org, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(org.status);
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage: org.logoUrl != null ? NetworkImage(org.logoUrl!) : null,
                    child: org.logoUrl == null
                        ? Text(org.name.isNotEmpty ? org.name[0] : 'O')
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(org.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(org.companyName ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      org.status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Plan: ${org.subscriptionId ?? '-'} - Nodes: ${org.nodeLimit ?? '-'}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Manage'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.login, size: 16, color: Colors.white),
                      label: const Text('Impersonate'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'trial':
        return Colors.orange;
      case 'suspended':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }
}
