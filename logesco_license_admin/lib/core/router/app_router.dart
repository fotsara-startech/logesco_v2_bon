import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../../pages/login/login_page.dart';
import '../../pages/dashboard/dashboard_page.dart';
import '../../pages/clients/clients_page.dart';
import '../../pages/clients/client_form_page.dart';
import '../../pages/licenses/licenses_page.dart';
import '../../pages/licenses/license_form_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../widgets/main_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = AuthService.instance.isLoggedIn;
      final isLoginRoute = state.fullPath == '/login';

      // Si pas connecté et pas sur la page de login, rediriger vers login
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      // Si connecté et sur la page de login, rediriger vers dashboard
      if (isLoggedIn && isLoginRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Route de connexion
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // Routes principales avec layout
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),

          // Clients
          GoRoute(
            path: '/clients',
            name: 'clients',
            builder: (context, state) => const ClientsPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'client-new',
                builder: (context, state) => const ClientFormPage(),
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'client-edit',
                builder: (context, state) {
                  final clientId = state.pathParameters['id']!;
                  return ClientFormPage(clientId: clientId);
                },
              ),
            ],
          ),

          // Licences
          GoRoute(
            path: '/licenses',
            name: 'licenses',
            builder: (context, state) => const LicensesPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'license-new',
                builder: (context, state) {
                  final clientId = state.uri.queryParameters['clientId'];
                  return LicenseFormPage(clientId: clientId);
                },
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'license-edit',
                builder: (context, state) {
                  final licenseId = state.pathParameters['id']!;
                  return LicenseFormPage(licenseId: licenseId);
                },
              ),
            ],
          ),

          // Paramètres
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'La page "${state.fullPath}" n\'existe pas.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Retour au tableau de bord'),
            ),
          ],
        ),
      ),
    ),
  );
});
