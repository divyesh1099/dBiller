import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/presentation/auth_controller.dart';
import 'store_repository.dart';
import 'account_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(storeProvider);
    final store = storeAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: store?.logoUrl != null ? NetworkImage(store!.logoUrl!) : null,
              child: store?.logoUrl == null ? const Icon(Icons.store, size: 16) : null,
            ),
            const SizedBox(width: 8),
            Text(store?.name ?? 'dBiller'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/account'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/pos');
              break;
            case 1:
              context.go('/inventory');
              break;
            case 2:
              context.go('/account');
              break;
          }
          Navigator.pop(context); // Close drawer
        },
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  backgroundImage: store?.logoUrl != null ? NetworkImage(store!.logoUrl!) : null,
                  child: store?.logoUrl == null ? const Icon(Icons.store, size: 24) : null,
                ),
                const SizedBox(height: 12),
                Text(
                  store?.name ?? 'dBiller',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                   'Store ID: ${store?.id ?? "-"}',
                   style: Theme.of(context).textTheme.bodySmall,
                )
              ],
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.point_of_sale),
            label: Text('POS / Billing'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.inventory),
            label: Text('Inventory'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings),
            label: Text('My Account'),
          ),
        ],
      ),
      body: child,
    );
  }
  int _calculateSelectedIndex(BuildContext context) {
    if (GoRouterState.of(context).uri.path.startsWith('/pos')) return 0;
    if (GoRouterState.of(context).uri.path.startsWith('/inventory')) return 1;
    if (GoRouterState.of(context).uri.path.startsWith('/account')) return 2;
    return 0;
  }
}
