import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';

import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/session_startup_screen.dart';
import '../../features/categories/screens/categories_screen.dart';
import '../../features/products/models/product.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/purchases/screens/purchases_screen.dart';
import '../../features/sales/screens/sales_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/startup',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;
      if (authState.isLoading || authState.hasError) {
        return location == '/startup' ? null : '/startup';
      }

      final user = authState.asData?.value;
      if (user == null) {
        if (location == '/login') return null;
        final destination = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$destination';
      }

      if (location == '/login' || location == '/startup') {
        return _safeDestination(state.uri.queryParameters['from']);
      }
      if (location.startsWith('/purchases') && !user.canViewPurchases) {
        return '/home';
      }
      if (location.startsWith('/sales') && !user.canViewSales) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/startup',
        builder: (_, _) => const SessionStartupScreen(),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            DashboardShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                builder: (_, _) => const ProductsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) {
                      final product = state.extra;
                      if (product is Product) {
                        return ProductDetailScreen(product: product);
                      }
                      return const _MissingProduct();
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/purchases',
                builder: (_, _) => const PurchasesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => PurchaseDetailScreen(
                      purchaseId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/sales', builder: (_, _) => const SalesScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'categories',
                    builder: (_, _) => const CategoriesScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.listen(authProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

String _safeDestination(String? destination) {
  if (destination == null ||
      !destination.startsWith('/') ||
      destination.startsWith('//')) {
    return '/home';
  }
  return destination;
}

class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).asData?.value;
    final destinations =
        <({int branch, String label, IconData icon, IconData selected})>[
          (
            branch: 0,
            label: 'Home',
            icon: Icons.home_outlined,
            selected: Icons.home,
          ),
          (
            branch: 1,
            label: 'Products',
            icon: Icons.inventory_2_outlined,
            selected: Icons.inventory_2,
          ),
          if (user?.canViewPurchases == true)
            (
              branch: 2,
              label: 'Purchases',
              icon: Icons.shopping_cart_outlined,
              selected: Icons.shopping_cart,
            ),
          if (user?.canViewSales == true)
            (
              branch: 3,
              label: 'Sales',
              icon: Icons.point_of_sale_outlined,
              selected: Icons.point_of_sale,
            ),
          (
            branch: 4,
            label: 'Settings',
            icon: Icons.settings_outlined,
            selected: Icons.settings,
          ),
        ];
    final selectedIndex = destinations.indexWhere(
      (item) => item.branch == navigationShell.currentIndex,
    );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (index) {
          final branch = destinations[index].branch;
          navigationShell.goBranch(
            branch,
            initialLocation: branch == navigationShell.currentIndex,
          );
        },
        destinations: destinations
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selected),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Stock-Flow')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Inventory at a glance',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your inventory overview will appear here as dashboard endpoints are integrated.',
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Manage products'),
            subtitle: const Text('Browse, search, and update your catalog'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/products'),
          ),
        ),
      ],
    ),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(user?.name ?? '', style: Theme.of(context).textTheme.titleLarge),
          Text(user?.email ?? ''),
          const SizedBox(height: 8),
          Text('Role: ${user?.role ?? 'Unknown'}'),
          if (user?.canManageCategories == true) ...[
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              subtitle: const Text('Manage the product categories'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/categories'),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              try {
                await ref.read(authProvider.notifier).signOut();
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ApiException.messageFor(error))),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _MissingProduct extends StatelessWidget {
  const _MissingProduct();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Product details')),
    body: const Center(
      child: Text(
        'Product details are unavailable. Return to the product list and try again.',
      ),
    ),
  );
}
