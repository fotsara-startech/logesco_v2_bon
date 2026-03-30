import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/auth_service.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        return isNarrow ? _MobileLayout(child: child) : _DesktopLayout(child: child);
      },
    );
  }
}

// ─── DESKTOP : sidebar fixe ──────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final Widget child;
  const _DesktopLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(isRail: false),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── MOBILE : drawer ─────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final Widget child;
  const _MobileLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: _Sidebar(isRail: false),
      ),
      appBar: AppBar(
        title: const Text('LOGESCO Admin'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: child,
    );
  }
}

// ─── SIDEBAR partagée ────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final bool isRail;
  const _Sidebar({required this.isRail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'LOGESCO Admin',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _NavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Tableau de bord', path: '/dashboard', index: 0),
                _NavItem(icon: Icons.people_outlined, selectedIcon: Icons.people, label: 'Clients', path: '/clients', index: 1),
                _NavItem(icon: Icons.key_outlined, selectedIcon: Icons.key, label: 'Licences', path: '/licenses', index: 2),
                _NavItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Paramètres', path: '/settings', index: 3),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
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
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Déconnecter')),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.instance.logout();
      if (context.mounted) context.go('/login');
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;
  final int index;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.path,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).fullPath ?? '';
    final isSelected = location.startsWith(path);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(isSelected ? selectedIcon : icon),
        title: Text(label),
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          // Ferme le drawer si ouvert (mobile)
          if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
          context.go(path);
        },
      ),
    );
  }
}
