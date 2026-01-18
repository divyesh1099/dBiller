import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_colors.dart';
import 'access_controller.dart';

class PermissionsLandingScreen extends ConsumerWidget {
  const PermissionsLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Permissions Matrix'),
      ),
      body: rolesAsync.when(
        data: (roles) {
          if (roles.isEmpty) {
            return const Center(child: Text('No roles available.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(role.description ?? 'No description'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/roles/${role.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Select a role to configure permissions.',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
