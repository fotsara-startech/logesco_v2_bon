import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/account_controller.dart';
import '../widgets/compte_client_card.dart';
import '../widgets/compte_fournisseur_card.dart';
import '../widgets/accounts_filter_dialog.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

/// Vue principale pour la liste des comptes clients et fournisseurs
class AccountsListView extends GetView<AccountController> {
  const AccountsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('accounts_title'.tr),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            tabs: [
              Tab(
                icon: const Icon(Icons.people),
                text: 'customers_title'.tr,
              ),
              Tab(
                icon: const Icon(Icons.business),
                text: 'suppliers_title'.tr,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'filter'.tr,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.refreshAll,
              tooltip: 'refresh'.tr,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildComptesClientsTab(),
            _buildComptesFournisseursTab(),
          ],
        ),
      ),
    );
  }

  /// Construit l'onglet des comptes clients
  Widget _buildComptesClientsTab() {
    return Column(
      children: [
        _buildSearchBar(
          hintText: 'sales_search_customer'.tr,
          onChanged: controller.updateSearchQueryClients,
          searchQuery: controller.searchQueryClients,
        ),
        _buildStatsCard(isClient: true),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingClients.value && controller.comptesClients.isEmpty) {
              return LoadingWidget(message: 'accounts_loading_clients'.tr);
            }

            if (controller.hasErrorClients.value && controller.comptesClients.isEmpty) {
              return ErrorDisplayWidget(
                message: controller.errorMessageClients.value,
                onRetry: () => controller.loadComptesClients(refresh: true),
              );
            }

            if (controller.comptesClients.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.account_balance_wallet,
                title: 'accounts_empty_clients_title'.tr,
                message: 'accounts_empty_clients_message'.tr,
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.loadComptesClients(refresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.comptesClients.length + (controller.hasMoreDataClients.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == controller.comptesClients.length) {
                    if (controller.isLoadingMoreClients.value) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        controller.loadComptesClients();
                      });
                      return const SizedBox.shrink();
                    }
                  }

                  final compte = controller.comptesClients[index];
                  return CompteClientCard(
                    compte: compte,
                    onTap: () => controller.goToCompteClientDetail(compte),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Construit l'onglet des comptes fournisseurs
  Widget _buildComptesFournisseursTab() {
    return Column(
      children: [
        _buildSearchBar(
          hintText: 'suppliers_search_placeholder'.tr,
          onChanged: controller.updateSearchQueryFournisseurs,
          searchQuery: controller.searchQueryFournisseurs,
        ),
        _buildStatsCard(isClient: false),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingFournisseurs.value && controller.comptesFournisseurs.isEmpty) {
              return LoadingWidget(message: 'accounts_loading_suppliers'.tr);
            }

            if (controller.hasErrorFournisseurs.value && controller.comptesFournisseurs.isEmpty) {
              return ErrorDisplayWidget(
                message: controller.errorMessageFournisseurs.value,
                onRetry: () => controller.loadComptesFournisseurs(refresh: true),
              );
            }

            if (controller.comptesFournisseurs.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.business_center,
                title: 'accounts_empty_suppliers_title'.tr,
                message: 'accounts_empty_suppliers_message'.tr,
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.loadComptesFournisseurs(refresh: true),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.comptesFournisseurs.length + (controller.hasMoreDataFournisseurs.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == controller.comptesFournisseurs.length) {
                    if (controller.isLoadingMoreFournisseurs.value) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        controller.loadComptesFournisseurs();
                      });
                      return const SizedBox.shrink();
                    }
                  }

                  final compte = controller.comptesFournisseurs[index];
                  return CompteFournisseurCard(
                    compte: compte,
                    onTap: () => controller.goToCompteFournisseurDetail(compte),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Construit la barre de recherche
  Widget _buildSearchBar({
    required String hintText,
    required Function(String) onChanged,
    required RxString searchQuery,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() => searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(''),
                )
              : const SizedBox.shrink()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Construit la carte de statistiques
  Widget _buildStatsCard({required bool isClient}) {
    return Obx(() {
      final nombreComptes = isClient ? controller.comptesClients.length : controller.comptesFournisseurs.length;

      final nombreEnDepassement = isClient ? controller.nombreComptesClientsEnDepassement : controller.nombreComptesFournisseursEnDepassement;

      final totalDettes = isClient ? controller.totalDettesClients : controller.totalDettesFournisseurs;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.account_balance_wallet,
              label: 'total'.tr,
              value: nombreComptes.toString(),
              color: Colors.blue,
            ),
            _buildStatItem(
              icon: Icons.warning,
              label: 'accounts_overlimit'.tr,
              value: nombreEnDepassement.toString(),
              color: Colors.orange,
            ),
            _buildStatItem(
              icon: Icons.attach_money,
              label: 'accounts_debts'.tr,
              value: '${totalDettes.toStringAsFixed(0)} FCFA',
              color: Colors.red,
            ),
          ],
        ),
      );
    });
  }

  /// Construit un élément de statistique
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Affiche la boîte de dialogue des filtres
  void _showFilterDialog() {
    showDialog(
      context: Get.context!,
      builder: (context) => AccountsFilterDialog(
        onApplyFilters: controller.applyFilters,
        onClearFilters: controller.clearFilters,
        currentSoldeMin: controller.soldeMinFilter.value,
        currentSoldeMax: controller.soldeMaxFilter.value,
        currentEnDepassement: controller.enDepassementFilter.value,
      ),
    );
  }
}
