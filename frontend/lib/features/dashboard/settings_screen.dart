import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../auth/presentation/auth_controller.dart';
import '../users/presentation/users_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;
    final isAdmin = user?.role == 'admin' || user?.role == 'superadmin';
    final isSuperadmin = user?.role == 'superadmin';
    final adminTiles = <Widget>[
      _NavTile(
        icon: Icons.groups,
        label: 'User Management',
        onTap: () => context.push('/users'),
      ),
      _NavTile(
        icon: Icons.security,
        label: 'Roles',
        onTap: () => context.push('/roles'),
      ),
      _NavTile(
        icon: Icons.grid_view,
        label: 'Permissions Matrix',
        onTap: () => context.push('/permissions'),
      ),
      _NavTile(
        icon: Icons.corporate_fare,
        label: 'Organizations',
        onTap: () => context.push('/organizations'),
      ),
      _NavTile(
        icon: Icons.subscriptions,
        label: 'Subscription Plans',
        onTap: () => context.push('/subscriptions'),
      ),
      if (isSuperadmin)
        _NavTile(
          icon: Icons.workspace_premium,
          label: 'Plan Manager',
          onTap: () => context.push('/plans'),
        ),
      if (isSuperadmin)
        _NavTile(
          icon: Icons.admin_panel_settings,
          label: 'Superadmin Dashboard',
          onTap: () => context.push('/superadmin'),
        ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (userAsync.isLoading) const SizedBox(height: 12),
          if (userAsync.isLoading) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          _Section(title: 'Operations', children: [
            _NavTile(
              icon: Icons.receipt_long,
              label: 'Orders',
              onTap: () => context.push('/orders'),
            ),
            _NavTile(
              icon: Icons.inventory_2,
              label: 'Inventory Management',
              onTap: () => context.push('/inventory/management'),
            ),
            _NavTile(
              icon: Icons.local_shipping,
              label: 'Suppliers',
              onTap: () => context.push('/suppliers'),
            ),
          ]),
          _Section(title: 'Billing', children: [
            _NavTile(
              icon: Icons.receipt,
              label: 'Invoices',
              onTap: () => context.go('/invoices'),
            ),
            _NavTile(
              icon: Icons.payments_outlined,
              label: 'Checkout',
              onTap: () => context.push('/checkout'),
            ),
          ]),
          if (isAdmin) _Section(title: 'Administration', children: adminTiles),
          _Section(title: 'Insights', children: [
            _NavTile(
              icon: Icons.analytics,
              label: 'Sales & Inventory Analytics',
              onTap: () => context.push('/analytics'),
            ),
          ]),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Sign out', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
