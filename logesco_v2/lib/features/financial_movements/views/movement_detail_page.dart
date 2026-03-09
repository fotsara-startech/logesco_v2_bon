import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/financial_movement.dart';
import '../controllers/financial_movement_controller.dart';
import '../../../shared/widgets/loading_widget.dart';

/// Page de détails d'un mouvement financier
class MovementDetailPage extends StatelessWidget {
  const MovementDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FinancialMovementController controller = Get.find<FinancialMovementController>();

    // Essayer de récupérer le mouvement depuis les arguments
    FinancialMovement? movement = Get.arguments as FinancialMovement?;

    // Si pas d'arguments, essayer de récupérer l'ID depuis les paramètres de route
    if (movement == null) {
      final String? movementId = Get.parameters['id'];
      if (movementId != null) {
        // Charger le mouvement depuis l'API avec l'ID
        return _buildLoadingView(movementId, controller);
      }
    }

    // Vérification de sécurité finale
    if (movement == null) {
      return _buildErrorView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('financial_movements_movement'.trParams({'reference': movement.reference})),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('/financial-movements/${movement.id}/edit', arguments: movement),
            icon: const Icon(Icons.edit),
            tooltip: 'edit'.tr,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteDialog(movement, controller);
                  break;
                case 'duplicate':
                  _duplicateMovement(movement);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: const Icon(Icons.copy),
                  title: Text('financial_movements_duplicate'.tr),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière de montant
            _buildAmountBanner(movement),
            const SizedBox(height: 24),

            // Informations principales
            _buildInfoCard(
              'financial_movements_general_info'.tr,
              Icons.info_outline,
              [
                _buildInfoRow('financial_movements_reference'.tr, movement.reference),
                _buildInfoRow('financial_movements_amount'.tr, movement.montantFormate),
                _buildInfoRow('financial_movements_description'.tr, movement.description),
                _buildInfoRow('financial_movements_date'.tr, _formatDate(movement.date)),
                if (movement.categorie != null) _buildCategoryRow('financial_movements_category'.tr, movement.categorie!),
              ],
            ),
            const SizedBox(height: 16),

            // Notes si présentes
            if (movement.notes != null && movement.notes!.isNotEmpty) ...[
              _buildInfoCard(
                'financial_movements_notes'.tr,
                Icons.note,
                [
                  _buildNotesSection(movement.notes!),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Informations système
            _buildInfoCard(
              'Informations système',
              Icons.schedule,
              [
                _buildInfoRow('Créé le', _formatDateTime(movement.dateCreation)),
                _buildInfoRow('Modifié le', _formatDateTime(movement.dateModification)),
                if (movement.utilisateurNom != null) _buildInfoRow('Créé par', movement.utilisateurNom!),
                _buildInfoRow('ID Utilisateur', '#${movement.utilisateurId}'),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/financial-movements/${movement.id}/edit', arguments: movement),
        tooltip: 'Modifier le mouvement',
        child: const Icon(Icons.edit),
      ),
    );
  }

  /// Construit la bannière de montant
  Widget _buildAmountBanner(FinancialMovement movement) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  _getCategoryIcon(movement.categorie?.icon),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sortie d\'argent',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      movement.montantFormate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (movement.categorie != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                movement.categorie!.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construit une carte d'informations
  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Construit une ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une ligne d'information pour la catégorie avec couleur
  Widget _buildCategoryRow(String label, dynamic category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category.color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section des notes
  Widget _buildNotesSection(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        notes,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  /// Obtient la couleur de la catégorie
  Color _getCategoryColor(String? colorHex) {
    if (colorHex != null) {
      try {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.grey;
      }
    }
    return Colors.grey;
  }

  /// Obtient l'icône de la catégorie
  IconData _getCategoryIcon(String? iconName) {
    if (iconName != null) {
      switch (iconName) {
        case 'shopping_cart':
          return Icons.shopping_cart;
        case 'receipt_long':
          return Icons.receipt_long;
        case 'people':
          return Icons.people;
        case 'build':
          return Icons.build;
        case 'local_shipping':
          return Icons.local_shipping;
        case 'more_horiz':
          return Icons.more_horiz;
        default:
          return Icons.receipt;
      }
    }
    return Icons.receipt;
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Formate une date avec l'heure
  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} à '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Affiche la boîte de dialogue de suppression
  void _showDeleteDialog(FinancialMovement movement, FinancialMovementController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('financial_movements_delete_confirm'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financial_movements_delete_confirm'.tr,
              style: TextStyle(color: Colors.grey.shade700),
            ),
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isDeleting.value
                    ? null
                    : () async {
                        final success = await controller.deleteMovement(movement.id);
                        Get.back(); // Ferme le dialog
                        if (success) {
                          Get.back(); // Retourne à la liste
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('delete'.tr),
              )),
        ],
      ),
    );
  }

  /// Duplique un mouvement
  void _duplicateMovement(FinancialMovement movement) {
    Get.toNamed('/financial-movements/create', arguments: {
      'duplicate': true,
      'movement': movement,
    });
  }

  /// Construit la vue d'erreur
  Widget _buildErrorView() {
    return Scaffold(
      appBar: AppBar(
        title: Text('error'.tr),
      ),
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
              'financial_movements_no_results'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Impossible d\'afficher les détails du mouvement.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed('/financial-movements'),
              icon: const Icon(Icons.arrow_back),
              label: Text('back'.tr),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la vue de chargement
  Widget _buildLoadingView(String movementId, FinancialMovementController controller) {
    return Scaffold(
      appBar: AppBar(
        title: Text('loading'.tr),
      ),
      body: FutureBuilder<FinancialMovement?>(
        future: _loadMovementById(movementId, controller),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingWidget(message: 'financial_movements_loading'.tr),
            );
          }

          if (snapshot.hasError) {
            return Center(
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
                    'error'.tr,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${'error'.tr}: ${snapshot.error}',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                    label: Text('back'.tr),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            // Reconstruit la page avec les données chargées
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.off(() => MovementDetailPage(), arguments: snapshot.data);
            });
            return Center(
              child: LoadingWidget(message: 'loading'.tr),
            );
          }

          return _buildErrorView();
        },
      ),
    );
  }

  /// Charge un mouvement par son ID
  Future<FinancialMovement?> _loadMovementById(String movementId, FinancialMovementController controller) async {
    try {
      // Vérifier que l'ID est un nombre valide
      if (movementId.isEmpty || !RegExp(r'^\d+$').hasMatch(movementId)) {
        throw FormatException('ID de mouvement invalide: "$movementId". L\'ID doit être un nombre.');
      }

      final id = int.parse(movementId);

      // Vérifier d'abord dans la liste existante
      final existingMovement = controller.movements.firstWhereOrNull((m) => m.id == id);
      if (existingMovement != null) {
        return existingMovement;
      }

      // Si pas trouvé, charger depuis l'API
      return await controller.getMovementById(id);
    } catch (e) {
      print('❌ Erreur lors du chargement du mouvement $movementId: $e');
      throw Exception('Impossible de charger le mouvement: $e');
    }
  }
}
