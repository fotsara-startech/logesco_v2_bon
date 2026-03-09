import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/permission_widget.dart';
import '../../../core/services/permission_service.dart';
import '../controllers/financial_movement_controller.dart';
import '../models/financial_movement.dart';

import '../widgets/movement_card.dart';
import '../widgets/movement_filters.dart';
import '../widgets/pagination_widget.dart';
import '../../../shared/widgets/loading_widget.dart';

/// Page principale pour la liste des mouvements financiers
class FinancialMovementsPage extends StatelessWidget {
  const FinancialMovementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FinancialMovementController controller = Get.find<FinancialMovementController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('financial_movements_title'.tr),
        actions: [
          // Bouton de rafraîchissement
          Obx(() => IconButton(
                onPressed: controller.isAnyLoading ? null : () => controller.refreshData(),
                icon: controller.isRefreshing.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'refresh'.tr,
              )),

          // Bouton de filtres
          IconButton(
            onPressed: () => _showFiltersBottomSheet(context, controller),
            icon: Obx(() => Stack(
                  children: [
                    const Icon(Icons.filter_list),
                    if (controller.hasActiveFilters)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                )),
            tooltip: 'financial_movements_filters'.tr,
          ),

          // Sélecteur de mode de pagination
          Obx(() => PaginationModeSelector(
                currentType: controller.paginationType.value,
                onChanged: (type) => controller.changePaginationType(type),
              )),

          const SizedBox(width: 8),

          // Bouton rapports
          IconButton(
            onPressed: () => _navigateToReports(),
            icon: const Icon(Icons.analytics),
            tooltip: 'financial_movements_reports'.tr,
          ),

          // Bouton nouveau mouvement
          IconButton(
            onPressed: () => _navigateToCreateMovement(),
            icon: const Icon(Icons.add),
            tooltip: 'financial_movements_new'.tr,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(context, controller),

          // Résumé des filtres actifs
          _buildActiveFiltersChips(controller),

          // Statistiques rapides
          _buildQuickStats(controller),

          // Accès rapide aux rapports
          _buildReportsAccess(),

          // Liste des mouvements
          Expanded(
            child: _buildMovementsList(controller),
          ),
        ],
      ),
      floatingActionButton: PermissionWidget(
        module: 'financial_movements',
        privilege: 'CREATE',
        child: FloatingActionButton(
          onPressed: () => _navigateToCreateMovement(),
          tooltip: 'financial_movements_new'.tr,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, FinancialMovementController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEnhancedSearchField(controller),

          // Indicateur de recherche active
          Obx(() {
            if (controller.searchQuery.value.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'financial_movements_search'.trParams({'query': controller.searchQuery.value}),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => controller.searchMovements(''),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips(FinancialMovementController controller) {
    return Obx(() {
      if (!controller.hasActiveFilters) return const SizedBox.shrink();

      final filters = controller.activeFiltersInfo;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'financial_movements_filter_active'.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => controller.resetFilters(),
                  child: Text('financial_movements_filter_clear'.tr),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: filters.entries.map((entry) {
                return Chip(
                  label: Text(
                    _formatFilterValue(entry.key, entry.value),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onDeleted: () => _removeFilter(controller, entry.key),
                  deleteIcon: const Icon(Icons.close, size: 16),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    });
  }

  Widget _buildQuickStats(FinancialMovementController controller) {
    return Obx(() {
      final stats = controller.quickStats;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total',
                '${stats['total'].toStringAsFixed(0)} FCFA',
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.blue.shade200,
            ),
            Expanded(
              child: _buildStatItem(
                'Nombre',
                '${stats['count']}',
                Icons.receipt_long,
                Colors.green,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.blue.shade200,
            ),
            Expanded(
              child: _buildStatItem(
                'Moyenne',
                '${stats['average'].toStringAsFixed(0)} FCFA',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label.tr,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildReportsAccess() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => _navigateToReports(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: Colors.purple.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'financial_movements_reports'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'financial_movements_reports_summary'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovementsList(FinancialMovementController controller) {
    return Obx(() {
      // État de chargement initial
      if (controller.isInitialLoading) {
        return Center(
          child: LoadingWidget(message: 'financial_movements_loading'.tr),
        );
      }

      // État d'erreur
      if (controller.error.value.isNotEmpty && controller.movements.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'error'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.error.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.loadMovements(),
                child: Text('customers_retry'.tr),
              ),
            ],
          ),
        );
      }

      // Liste vide
      if (controller.movements.isEmpty) {
        return _buildEmptyState(controller);
      }

      // Construction de la liste selon le mode de pagination
      return _buildMovementsListView(controller);
    });
  }

  Widget _buildEmptyState(FinancialMovementController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            controller.hasActiveFilters ? 'financial_movements_no_results'.tr : 'no_data'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.hasActiveFilters ? 'Essayez de modifier vos filtres' : 'Commencez par créer votre premier mouvement',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          if (controller.hasActiveFilters)
            OutlinedButton(
              onPressed: () => controller.resetFilters(),
              child: Text('financial_movements_filter_clear'.tr),
            )
          else
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateMovement(),
              icon: const Icon(Icons.add),
              label: Text('financial_movements_new'.tr),
            ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet(BuildContext context, FinancialMovementController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MovementFilters(controller: controller),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    FinancialMovementController controller,
    FinancialMovement movement,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('financial_movements_delete'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('financial_movements_delete_confirm'.tr),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'financial_movements_reference'.tr}: ${movement.reference}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text('${'financial_movements_amount'.tr}: ${movement.montantFormate}'),
                  Text('${'financial_movements_description'.tr}: ${movement.description}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette action est irréversible.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: controller.isDeleting.value
                ? null
                : () async {
                    final success = await controller.deleteMovement(movement.id);
                    Get.back();
                    if (success) {
                      Get.snackbar(
                        'success'.tr,
                        'Mouvement supprimé avec succès',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green.shade100,
                        colorText: Colors.green.shade800,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: controller.isDeleting.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  String _formatFilterValue(String key, dynamic value) {
    switch (key) {
      case 'search':
        return 'Recherche: $value';
      case 'category':
        return 'Catégorie: $value';
      case 'startDate':
        return 'Depuis: ${_formatDate(value)}';
      case 'endDate':
        return 'Jusqu\'au: ${_formatDate(value)}';
      case 'minAmount':
        return 'Min: ${value.toStringAsFixed(0)} FCFA';
      case 'maxAmount':
        return 'Max: ${value.toStringAsFixed(0)} FCFA';
      default:
        return '$key: $value';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _removeFilter(FinancialMovementController controller, String filterKey) {
    switch (filterKey) {
      case 'search':
        controller.searchMovements('');
        break;
      case 'category':
        controller.filterByCategory(null);
        break;
      case 'startDate':
        controller.filterByDateRange(null, controller.endDate.value);
        break;
      case 'endDate':
        controller.filterByDateRange(controller.startDate.value, null);
        break;
      case 'minAmount':
        controller.filterByAmountRange(null, controller.maxAmount.value);
        break;
      case 'maxAmount':
        controller.filterByAmountRange(controller.minAmount.value, null);
        break;
    }
  }

  void _navigateToCreateMovement() {
    Get.toNamed('/financial-movements/create');
  }

  void _navigateToReports() {
    Get.toNamed('/financial-movements/reports');
  }

  void _navigateToMovementDetail(FinancialMovement movement) {
    Get.toNamed('/financial-movements/${movement.id}', arguments: movement);
  }

  void _navigateToEditMovement(FinancialMovement movement) {
    Get.toNamed('/financial-movements/${movement.id}/edit', arguments: movement);
  }

  Widget _buildEnhancedSearchField(FinancialMovementController controller) {
    return Column(
      children: [
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 2) {
              return const Iterable<String>.empty();
            }
            return await controller.getSearchSuggestions(textEditingValue.text);
          },
          onSelected: (String selection) {
            controller.searchMovements(selection);
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            // Synchronise avec la valeur actuelle du contrôleur
            if (controller.searchQuery.value.isNotEmpty && textEditingController.text != controller.searchQuery.value) {
              textEditingController.text = controller.searchQuery.value;
            }

            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              onChanged: (value) => controller.searchMovements(value),
              onSubmitted: (value) => onFieldSubmitted(),
              decoration: InputDecoration(
                hintText: 'Rechercher par description, référence, notes...',
                helperText: 'Utilisez "desc:", "ref:", "notes:", "user:" pour une recherche ciblée',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              textEditingController.clear();
                              controller.searchMovements('');
                            },
                            icon: const Icon(Icons.clear),
                            tooltip: 'Effacer la recherche',
                          )
                        : const SizedBox.shrink()),
                    IconButton(
                      onPressed: () => _showAdvancedSearchDialog(context, controller),
                      icon: const Icon(Icons.tune),
                      tooltip: 'Recherche avancée',
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.search, size: 16),
                        title: Text(
                          option,
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),

        // Chips pour les recherches rapides
        const SizedBox(height: 8),
        _buildQuickSearchChips(controller),
      ],
    );
  }

  Widget _buildQuickSearchChips(FinancialMovementController controller) {
    return Obx(() {
      final recentSearches = _getRecentSearchTerms();
      if (recentSearches.isEmpty) return const SizedBox.shrink();

      return Wrap(
        spacing: 8,
        children: recentSearches
            .map((term) => ActionChip(
                  label: Text(term, style: const TextStyle(fontSize: 12)),
                  onPressed: () => controller.searchMovements(term),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide(color: Colors.blue.shade200),
                ))
            .toList(),
      );
    });
  }

  List<String> _getRecentSearchTerms() {
    // Retourne des termes de recherche fréquents basés sur les mouvements actuels
    final controller = Get.find<FinancialMovementController>();

    // Extrait des mots-clés fréquents des descriptions
    final wordFrequency = <String, int>{};
    for (final movement in controller.movements.take(50)) {
      final words = movement.description.toLowerCase().split(' ');
      for (final word in words) {
        if (word.length > 3 && !_isCommonWord(word)) {
          wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
        }
      }
    }

    // Retourne les 5 mots les plus fréquents
    final sortedWords = wordFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(5).map((e) => e.key).toList();
  }

  bool _isCommonWord(String word) {
    const commonWords = {'pour', 'avec', 'dans', 'sur', 'par', 'de', 'du', 'des', 'le', 'la', 'les', 'un', 'une', 'et', 'ou', 'mais', 'donc', 'car'};
    return commonWords.contains(word.toLowerCase());
  }

  void _showAdvancedSearchDialog(BuildContext context, FinancialMovementController controller) {
    showDialog(
      context: context,
      builder: (context) => _AdvancedSearchDialog(controller: controller),
    );
  }

  /// Construit la liste des mouvements selon le mode de pagination
  Widget _buildMovementsListView(FinancialMovementController controller) {
    if (controller.paginationType.value == PaginationType.infinite) {
      return _buildInfiniteScrollList(controller);
    } else {
      return _buildPagedList(controller);
    }
  }

  /// Liste avec pagination infinie (scroll)
  Widget _buildInfiniteScrollList(FinancialMovementController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.movements.length + (controller.canLoadMore.value ? 1 : 0),
      itemBuilder: (context, index) {
        // Élément de chargement pour pagination infinie
        if (index == controller.movements.length) {
          if (controller.isLoadingMore.value) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            // Déclenche le chargement automatique
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.loadMore();
            });
            return const SizedBox.shrink();
          }
        }

        final movement = controller.movements[index];
        final permissionService = Get.find<PermissionService>();
        final canUpdate = permissionService.hasPermission('financial_movements', 'UPDATE');
        final canDelete = permissionService.hasPermission('financial_movements', 'DELETE');

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MovementCard(
            movement: movement,
            searchQuery: controller.searchQuery.value,
            onTap: () => _navigateToMovementDetail(movement),
            onEdit: canUpdate ? () => _navigateToEditMovement(movement) : null,
            onDelete: canDelete ? () => _showDeleteConfirmation(context, controller, movement) : null,
          ),
        );
      },
    );
  }

  /// Liste avec pagination par pages
  Widget _buildPagedList(FinancialMovementController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.movements.length,
      itemBuilder: (context, index) {
        final movement = controller.movements[index];
        final permissionService = Get.find<PermissionService>();
        final canUpdate = permissionService.hasPermission('financial_movements', 'UPDATE');
        final canDelete = permissionService.hasPermission('financial_movements', 'DELETE');

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MovementCard(
            movement: movement,
            searchQuery: controller.searchQuery.value,
            onTap: () => _navigateToMovementDetail(movement),
            onEdit: canUpdate ? () => _navigateToEditMovement(movement) : null,
            onDelete: canDelete ? () => _showDeleteConfirmation(context, controller, movement) : null,
          ),
        );
      },
    );
  }
}

/// Dialog pour la recherche avancée
class _AdvancedSearchDialog extends StatefulWidget {
  final FinancialMovementController controller;

  const _AdvancedSearchDialog({required this.controller});

  @override
  State<_AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends State<_AdvancedSearchDialog> {
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final _userController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recherche avancée'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Rechercher dans les descriptions...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Référence',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
                hintText: 'Numéro de référence...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Rechercher dans les notes...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: 'Utilisateur',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: 'Nom de l\'utilisateur...',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Laissez vide les champs non utilisés. La recherche s\'effectue sur tous les champs remplis.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _clearAll,
          child: const Text('Effacer tout'),
        ),
        ElevatedButton(
          onPressed: _search,
          child: const Text('Rechercher'),
        ),
      ],
    );
  }

  Widget _buildEnhancedSearchField(FinancialMovementController controller) {
    return Column(
      children: [
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 2) {
              return const Iterable<String>.empty();
            }
            return await controller.getSearchSuggestions(textEditingValue.text);
          },
          onSelected: (String selection) {
            controller.searchMovements(selection);
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            // Synchronise avec la valeur actuelle du contrôleur
            if (controller.searchQuery.value.isNotEmpty && textEditingController.text != controller.searchQuery.value) {
              textEditingController.text = controller.searchQuery.value;
            }

            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              onChanged: (value) => controller.searchMovements(value),
              onSubmitted: (value) => onFieldSubmitted(),
              decoration: InputDecoration(
                hintText: 'Rechercher par description, référence, notes...',
                helperText: 'Utilisez "desc:", "ref:", "notes:", "user:" pour une recherche ciblée',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              textEditingController.clear();
                              controller.searchMovements('');
                            },
                            icon: const Icon(Icons.clear),
                            tooltip: 'Effacer la recherche',
                          )
                        : const SizedBox.shrink()),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close current dialog
                        showDialog(
                          context: context,
                          builder: (context) => _AdvancedSearchDialog(controller: controller),
                        );
                      },
                      icon: const Icon(Icons.tune),
                      tooltip: 'Recherche avancée',
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.search, size: 16),
                        title: Text(
                          option,
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),

        // Chips pour les recherches rapides
        const SizedBox(height: 8),
        _buildQuickSearchChips(controller),
      ],
    );
  }

  Widget _buildQuickSearchChips(FinancialMovementController controller) {
    return Obx(() {
      final recentSearches = _getRecentSearchTerms();
      if (recentSearches.isEmpty) return const SizedBox.shrink();

      return Wrap(
        spacing: 8,
        children: recentSearches
            .map((term) => ActionChip(
                  label: Text(term, style: const TextStyle(fontSize: 12)),
                  onPressed: () => controller.searchMovements(term),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide(color: Colors.blue.shade200),
                ))
            .toList(),
      );
    });
  }

  List<String> _getRecentSearchTerms() {
    // Retourne des termes de recherche fréquents basés sur les mouvements actuels
    final controller = Get.find<FinancialMovementController>();

    // Extrait des mots-clés fréquents des descriptions
    final wordFrequency = <String, int>{};
    for (final movement in controller.movements.take(50)) {
      final words = movement.description.toLowerCase().split(' ');
      for (final word in words) {
        if (word.length > 3 && !_isCommonWord(word)) {
          wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
        }
      }
    }

    // Retourne les 5 mots les plus fréquents
    final sortedWords = wordFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(5).map((e) => e.key).toList();
  }

  bool _isCommonWord(String word) {
    const commonWords = {'pour', 'avec', 'dans', 'sur', 'par', 'de', 'du', 'des', 'le', 'la', 'les', 'un', 'une', 'et', 'ou', 'mais', 'donc', 'car'};
    return commonWords.contains(word.toLowerCase());
  }

  void _clearAll() {
    _descriptionController.clear();
    _referenceController.clear();
    _notesController.clear();
    _userController.clear();
  }

  void _search() {
    final hasAnySearch = _descriptionController.text.isNotEmpty || _referenceController.text.isNotEmpty || _notesController.text.isNotEmpty || _userController.text.isNotEmpty;

    if (!hasAnySearch) {
      Get.snackbar(
        'Recherche vide',
        'Veuillez remplir au moins un champ de recherche',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    widget.controller.advancedSearch(
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      reference: _referenceController.text.isNotEmpty ? _referenceController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      userName: _userController.text.isNotEmpty ? _userController.text : null,
    );

    Navigator.of(context).pop();
  }
}
