import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/database_service.dart';
import '../../models/license.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/recent_licenses_widget.dart';
import '../../widgets/expiring_licenses_widget.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Map<String, int>? _stats;
  List<License>? _recentLicenses;
  List<License>? _expiringLicenses;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final stats = await DatabaseService.instance.getStatistics();
      final recentLicenses = await DatabaseService.instance.getLicenses(limit: 5);

      // Licences expirant dans les 30 prochains jours
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));
      final allLicenses = await DatabaseService.instance.getLicenses();
      final expiringLicenses = allLicenses.where((license) {
        return license.isActive && license.expiresAt.isAfter(now) && license.expiresAt.isBefore(thirtyDaysFromNow);
      }).toList();

      setState(() {
        _stats = stats;
        _recentLicenses = recentLicenses;
        _expiringLicenses = expiringLicenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message de bienvenue
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
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
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bienvenue dans LOGESCO License Admin',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Gérez vos clients et leurs licences facilement',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/clients/new'),
                              icon: const Icon(Icons.add),
                              label: const Text('Nouveau client'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistiques
                    Text(
                      'Statistiques',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    if (_stats != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              title: 'Clients',
                              value: _stats!['totalClients']?.toString() ?? '0',
                              icon: Icons.people,
                              color: Colors.blue,
                              onTap: () => context.go('/clients'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatsCard(
                              title: 'Licences actives',
                              value: _stats!['activeLicenses']?.toString() ?? '0',
                              icon: Icons.key,
                              color: Colors.green,
                              onTap: () => context.go('/licenses'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              title: 'Total licences',
                              value: _stats!['totalLicenses']?.toString() ?? '0',
                              icon: Icons.inventory,
                              color: Colors.orange,
                              onTap: () => context.go('/licenses'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatsCard(
                              title: 'Licences expirées',
                              value: _stats!['expiredLicenses']?.toString() ?? '0',
                              icon: Icons.warning,
                              color: Colors.red,
                              onTap: () => context.go('/licenses'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Actions rapides
                    Text(
                      'Actions rapides',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () => context.go('/clients/new'),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(Icons.person_add, size: 32, color: Colors.blue),
                                    SizedBox(height: 8),
                                    Text('Ajouter un client'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () => context.go('/licenses/new'),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(Icons.key_outlined, size: 32, color: Colors.green),
                                    SizedBox(height: 8),
                                    Text('Générer une licence'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Licences récentes et expirant bientôt
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Licences récentes
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Licences récentes',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              RecentLicensesWidget(licenses: _recentLicenses ?? []),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Licences expirant bientôt
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expirent bientôt',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              ExpiringLicensesWidget(licenses: _expiringLicenses ?? []),
                            ],
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
}
