import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/auth_service.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar personnalisée
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // En-tête
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LOGESCO Admin',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Menu de navigation
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _buildNavItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        selectedIcon: Icons.dashboard,
                        label: 'Tableau de bord',
                        path: '/dashboard',
                        index: 0,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.people_outlined,
                        selectedIcon: Icons.people,
                        label: 'Clients',
                        path: '/clients',
                        index: 1,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.key_outlined,
                        selectedIcon: Icons.key,
                        label: 'Licences',
                        path: '/licenses',
                        index: 2,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings,
                        label: 'Paramètres',
                        path: '/settings',
                        index: 3,
                      ),
                    ],
                  ),
                ),

                // Bouton de déconnexion
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Déconnexion'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Séparateur vertical
          const VerticalDivider(width: 1, thickness: 1),

          // Contenu principal
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String path,
    required int index,
  }) {
    final isSelected = _getSelectedIndex(context) == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(isSelected ? selectedIcon : icon),
        title: Text(label),
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () => context.go(path),
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).fullPath;

    if (location!.startsWith('/dashboard')) return 0;
    if (location.startsWith('/clients')) return 1;
    if (location.startsWith('/licenses')) return 2;
    if (location.startsWith('/settings')) return 3;

    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/clients');
        break;
      case 2:
        context.go('/licenses');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.instance.logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}
