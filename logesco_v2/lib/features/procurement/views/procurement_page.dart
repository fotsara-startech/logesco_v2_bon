/**
 * Page principale de gestion des approvisionnements avec contrôle des permissions
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/procurement_controller.dart';
import '../models/procurement_models.dart';
import '../widgets/commande_card.dart';
import '../widgets/create_commande_dialog.dart';
import '../widgets/receive_commande_dialog.dart';
import '../widgets/cancel_commande_dialog.dart';
import '../widgets/commande_details_dialog.dart';
import '../widgets/filtres_commandes_widget.dart';
import '../widgets/alertes_approvisionnement_widget.dart';
import '../../../core/widgets/permission_widget.dart';
import '../../../core/services/permission_service.dart';

class ProcurementPage extends StatefulWidget {
  const ProcurementPage({Key? key}) : super(key: key);

  @override
  State<ProcurementPage> createState() => _ProcurementPageState();
}

class _ProcurementPageState extends State<ProcurementPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final controller = Get.find<ProcurementController>();
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 500) {
      print('📜 SCROLL VERS FIN DÉTECTÉ (Procurement)');
      print('   - Position: ${_scrollController.position.pixels}');
      print('   - MaxExtent: ${_scrollController.position.maxScrollExtent}');
      print('   - hasMoreCommandes: ${controller.hasMoreCommandes.value}');
      print('   - isLoading: ${controller.isLoading.value}');

      if (controller.hasMoreCommandes.value && !controller.isLoading.value) {
        print('✅ Chargement de la page suivante...');
        controller.loadCommandes();
      } else {
        print('⚠️ Impossible de charger: hasMore=${controller.hasMoreCommandes.value}, loading=${controller.isLoading.value}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProcurementController>();

    return PermissionWidget(
      module: 'procurement',
      privilege: 'READ',
      fallback: Scaffold(
        appBar: AppBar(
          title: const Text('Accès refusé'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Accès refusé',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous n\'avez pas les privilèges nécessaires\npour accéder à la gestion des approvisionnements',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
      showFallback: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approvisionnements'),
          actions: [
            // Badge pour les alertes
            Obx(() => controller.nombreAlertes.value > 0
                ? Badge(
                    label: Text(controller.nombreAlertes.value.toString()),
                    child: IconButton(
                      icon: const Icon(Icons.warning),
                      onPressed: () => _showAlertes(context, controller),
                    ),
                  )
                : const SizedBox.shrink()),

            // Bouton suggestions d'approvisionnement
            PermissionWidget(
              module: 'procurement',
              privilege: 'READ',
              child: IconButton(
                icon: const Icon(Icons.lightbulb_outline),
                onPressed: () => _showSuggestions(context),
                tooltip: 'Suggestions d\'approvisionnement',
              ),
            ),

            // Bouton de filtres
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFiltres(context, controller),
            ),

            // Bouton de rafraîchissement
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.loadCommandes(refresh: true),
            ),
          ],
        ),
        body: Column(
          children: [
            // Statistiques rapides
            _buildStatistiques(controller),

            // Liste des commandes
            Expanded(
              child: Obx(() {
                print('=== 📋 WIDGET RECONSTRUCTION (Procurement) ===');
                print('   - Commandes chargées: ${controller.commandes.length}');
                print('   - Total pagination: ${controller.totalCommandes.value}');
                print('   - Page: ${controller.currentPage.value - 1}/${controller.totalPages.value}');
                print('   - hasMoreCommandes: ${controller.hasMoreCommandes.value}');
                print('   - isLoading: ${controller.isLoading.value}');
                print('=====================================');

                if (controller.isLoading.value && controller.commandes.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.commandes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune commande d\'approvisionnement',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez votre première commande',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => controller.loadCommandes(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.commandes.length + (controller.hasMoreCommandes.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.commandes.length) {
                        return Obx(() => controller.isLoading.value
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink());
                      }

                      final commande = controller.commandes[index];
                      return CommandeCard(
                        commande: commande,
                        onTap: () => _showCommandeDetails(context, commande),
                        onReceive: (commande.peutEtreReceptionnee && _hasReceivePermission()) ? () => _showReceptionDialog(context, commande, controller) : null,
                        onCancel: (commande.peutEtreModifiee && _hasUpdatePermission()) ? () => _confirmCancelCommande(context, commande, controller) : null,
                        onExportPdf: () => _exportCommandeToPdf(context, commande, controller),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
        floatingActionButton: PermissionWidget(
          module: 'procurement',
          privilege: 'CREATE',
          child: FloatingActionButton.extended(
            onPressed: () => _showCreateCommandeDialog(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle commande'),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistiques(ProcurementController controller) {
    return Obx(() {
      final commandes = controller.commandes;
      final enAttente = commandes.where((c) => c.statut == CommandeStatut.enAttente).length;
      final partielles = commandes.where((c) => c.statut == CommandeStatut.partielle).length;
      final terminees = commandes.where((c) => c.statut == CommandeStatut.terminee).length;

      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'En attente',
                enAttente.toString(),
                Colors.orange,
                Icons.schedule,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Partielles',
                partielles.toString(),
                Colors.blue,
                Icons.hourglass_bottom,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Terminées',
                terminees.toString(),
                Colors.green,
                Icons.check_circle,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCommandeDialog(BuildContext context, ProcurementController controller) {
    showDialog(
      context: context,
      builder: (context) => CreateCommandeDialog(controller: controller),
    );
  }

  void _showCommandeDetails(BuildContext context, CommandeApprovisionnement commande) {
    final controller = Get.find<ProcurementController>();
    showDialog(
      context: context,
      builder: (context) => CommandeDetailsDialog(
        commande: commande,
        controller: controller,
      ),
    );
  }

  void _showReceptionDialog(BuildContext context, CommandeApprovisionnement commande, ProcurementController controller) {
    showDialog(
      context: context,
      builder: (context) => ReceiveCommandeDialog(
        commande: commande,
        controller: controller,
      ),
    );
  }

  void _confirmCancelCommande(BuildContext context, CommandeApprovisionnement commande, ProcurementController controller) {
    showDialog(
      context: context,
      builder: (context) => CancelCommandeDialog(
        commande: commande,
        controller: controller,
      ),
    );
  }

  void _showFiltres(BuildContext context, ProcurementController controller) {
    showDialog(
      context: context,
      builder: (context) => FiltresCommandesWidget(controller: controller),
    );
  }

  void _showAlertes(BuildContext context, ProcurementController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertesApprovisionnementWidget(controller: controller),
    );
  }

  /// Vérifie si l'utilisateur a les permissions de réception
  bool _hasReceivePermission() {
    final permissionService = Get.find<PermissionService>();
    return permissionService.hasPermission('procurement', 'RECEIVE');
  }

  /// Vérifie si l'utilisateur a les permissions de modification
  bool _hasUpdatePermission() {
    final permissionService = Get.find<PermissionService>();
    return permissionService.hasPermission('procurement', 'UPDATE');
  }

  /// Affiche la page des suggestions d'approvisionnement
  void _showSuggestions(BuildContext context) {
    Get.toNamed('/procurement/suggestions');
  }

  /// Exporte une commande en PDF
  void _exportCommandeToPdf(BuildContext context, CommandeApprovisionnement commande, ProcurementController controller) async {
    try {
      final filePath = await controller.exportCommandeToPdf(commande);
      if (filePath != null) {
        // Afficher un message de succès avec option d'ouvrir le fichier
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande exportée: ${filePath.split('/').last}'),
            action: SnackBarAction(
              label: 'Ouvrir',
              onPressed: () {
                // TODO: Implémenter l'ouverture du fichier PDF
                // Utiliser un package comme open_file ou url_launcher
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
