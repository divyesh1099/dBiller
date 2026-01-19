import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/billing/presentation/ai_image_scanner_screen.dart';
import '../features/billing/presentation/pos_screen.dart';
import '../features/dashboard/analytics_screen.dart';
import '../features/dashboard/home_screen.dart';
import '../features/dashboard/main_shell.dart';
import '../features/dashboard/settings_screen.dart';
import '../features/dashboard/superadmin_dashboard_screen.dart';
import '../features/dashboard/superadmin_onboard_screen.dart';
import '../features/items/presentation/inventory_management_screen.dart';
import '../features/items/presentation/item_details_screen.dart';
import '../features/items/presentation/item_edit_screen.dart';
import '../features/items/presentation/item_form_screen.dart';
import '../features/items/presentation/item_list_screen.dart';
import '../features/invoices/presentation/invoice_details_screen.dart';
import '../features/invoices/presentation/invoice_edit_screen.dart';
import '../features/invoices/presentation/invoice_form_screen.dart';
import '../features/invoices/presentation/invoices_list_screen.dart';
import '../features/orders/presentation/order_details_screen.dart';
import '../features/orders/presentation/order_edit_screen.dart';
import '../features/orders/presentation/order_form_screen.dart';
import '../features/orders/presentation/orders_list_screen.dart';
import '../features/suppliers/presentation/supplier_details_screen.dart';
import '../features/suppliers/presentation/supplier_edit_screen.dart';
import '../features/suppliers/presentation/supplier_form_screen.dart';
import '../features/suppliers/presentation/supplier_list_screen.dart';
import '../features/subscriptions/presentation/plan_manager_screen.dart';
import '../features/subscriptions/presentation/subscription_plans_screen.dart';
import '../features/organizations/presentation/organization_management_screen.dart';
import '../features/organizations/presentation/organization_edit_screen.dart';
import '../features/organizations/presentation/organization_setup_screen.dart';
import '../features/users/presentation/user_details_screen.dart';
import '../features/users/presentation/user_form_screen.dart';
import '../features/users/presentation/user_list_screen.dart';
import '../features/access/presentation/roles_management_screen.dart';
import '../features/access/presentation/permissions_matrix_screen.dart';
import '../features/access/presentation/permissions_landing_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home',
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const ItemListScreen(),
            routes: [
              GoRoute(
                path: 'items/new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ItemFormScreen(),
              ),
              GoRoute(
                path: 'items/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => ItemDetailsScreen(
                  itemId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'items/:id/edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => ItemEditScreen(
                  itemId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'management',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const InventoryManagementScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/invoices',
            builder: (context, state) => const InvoicesListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const InvoiceFormScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => InvoiceDetailsScreen(
                  invoiceId: int.parse(state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: ':id/edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => InvoiceEditScreen(
                  invoiceId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const OrderFormScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => OrderDetailsScreen(
              orderId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: ':id/edit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => OrderEditScreen(
              orderId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/suppliers',
        builder: (context, state) => const SupplierListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const SupplierFormScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => SupplierDetailsScreen(
              supplierId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: ':id/edit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => SupplierEditScreen(
              supplierId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UserListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const UserFormScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => UserDetailsScreen(
              userId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/roles',
        builder: (context, state) => const RolesManagementScreen(),
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => PermissionsMatrixScreen(
              roleId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) => const PermissionsLandingScreen(),
      ),
      GoRoute(
        path: '/organizations',
        builder: (context, state) => const OrganizationManagementScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const OrganizationSetupScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => OrganizationEditScreen(
              organizationId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: ':id/subscriptions',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => SubscriptionPlansScreen(
              organizationId: int.parse(state.pathParameters['id']!),
              title: 'Organization Subscriptions',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/subscriptions',
        builder: (context, state) => const SubscriptionPlansScreen(),
      ),
      GoRoute(
        path: '/plans',
        builder: (context, state) => const PlanManagerScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/superadmin',
        builder: (context, state) => const SuperadminDashboardScreen(),
      ),
      GoRoute(
        path: '/superadmin/onboard',
        builder: (context, state) => const SuperadminOnboardScreen(),
      ),
      GoRoute(
        path: '/ai-scanner',
        builder: (context, state) => const AiImageScannerScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const POSScreen(),
      ),
    ],
  );
});
