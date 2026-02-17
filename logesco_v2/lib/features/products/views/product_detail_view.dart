import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../controllers/product_detail_controller.dart';
import '../widgets/expiration_dates_list_widget.dart';
import '../../../shared/constants/constants.dart';
import '../../../core/widgets/permission_widget.dart';

/// Vue des détails d'un produit
class ProductDetailView extends StatelessWidget {
  const ProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductDetailController());

    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingView();
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return _buildErrorView(controller.errorMessage.value);
      }

      final product = controller.product.value;
      if (product == null) {
        return _buildErrorView('Produit non trouvé');
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(product.nom),
          elevation: 0,
          actions: [
            PermissionWidget(
              module: 'products',
              privilege: 'UPDATE',
              child: IconButton(
                onPressed: () => Get.toNamed('/products/${product.id}/edit', arguments: product),
                icon: const Icon(Icons.edit),
                tooltip: 'Modifier',
              ),
            ),
            PermissionWidget(
              module: 'products',
              privilege: 'DELETE',
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      _showDeleteDialog(product);
                      break;
                    case 'duplicate':
                      _duplicateProduct(product);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Dupliquer'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statut du produit
              _buildStatusBanner(product),
              const SizedBox(height: 24),

              // Informations principales
              _buildInfoCard(
                'Informations générales',
                Icons.info_outline,
                [
                  _buildInfoRow('Référence', product.reference),
                  _buildInfoRow('Nom', product.nom),
                  if (product.description != null && product.description!.isNotEmpty) _buildInfoRow('Description', product.description!),
                  if (product.categorie != null && product.categorie!.isNotEmpty) _buildInfoRow('Catégorie', product.categorie!),
                ],
              ),
              const SizedBox(height: 16),

              // Informations commerciales
              _buildInfoCard(
                'Informations commerciales',
                Icons.attach_money,
                [
                  _buildInfoRow('Prix de vente', CurrencyConstants.formatAmount(product.prixUnitaire)),
                  if (product.prixAchat != null) ...[
                    _buildInfoRow('Prix d\'achat', CurrencyConstants.formatAmount(product.prixAchat!)),
                    _buildInfoRow('Marge', product.marge != null ? CurrencyConstants.formatAmount(product.marge!) : 'N/A'),
                    _buildInfoRow('% Marge', product.pourcentageMarge != null ? '${product.pourcentageMarge!.toStringAsFixed(1)}%' : 'N/A'),
                  ],
                  if (product.codeBarre != null && product.codeBarre!.isNotEmpty) _buildInfoRow('Code-barre', product.codeBarre!),
                  if (product.categorie != null && product.categorie!.isNotEmpty)
                    _buildInfoRow('Catégorie', product.categorie!)
                  else if (product.categorieId != null)
                    _buildInfoRow('Catégorie', 'ID: ${product.categorieId} (nom non résolu)')
                  else
                    _buildInfoRow('Catégorie', 'Aucune'),
                  if (!product.estService) _buildInfoRow('Seuil de stock', '${product.seuilStockMinimum} unités'),
                ],
              ),
              const SizedBox(height: 16),

              // Informations système
              _buildInfoCard(
                'Informations système',
                Icons.schedule,
                [
                  _buildInfoRow('Date de création', _formatDate(product.dateCreation)),
                  _buildInfoRow('Dernière modification', _formatDate(product.dateModification)),
                  _buildInfoRow('Type', product.estService ? 'Service' : 'Produit physique'),
                  _buildInfoRow('Statut', product.estActif ? 'Actif' : 'Inactif'),
                  _buildInfoRow('Gestion péremption', product.gestionPeremption ? 'Activée' : 'Désactivée'),
                ],
              ),
              const SizedBox(height: 16),

              // Dates de péremption (si activé)
              if (product.gestionPeremption) ...[
                _buildExpirationDatesSection(product),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        floatingActionButton: PermissionWidget(
          module: 'products',
          privilege: 'UPDATE',
          child: FloatingActionButton(
            onPressed: () => Get.toNamed('/products/${product.id}/edit', arguments: product),
            tooltip: 'Modifier le produit',
            child: const Icon(Icons.edit),
          ),
        ),
      );
    });
  }

  /// Construit la bannière de statut
  Widget _buildStatusBanner(Product product) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: product.estActif ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: product.estActif ? Colors.green.shade200 : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            product.estActif ? Icons.check_circle : Icons.cancel,
            color: product.estActif ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.estActif ? 'Produit actif' : 'Produit inactif',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: product.estActif ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                Text(
                  product.estActif ? 'Ce produit est disponible pour les ventes' : 'Ce produit est désactivé et non disponible pour les ventes',
                  style: TextStyle(
                    fontSize: 12,
                    color: product.estActif ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte d'informations
  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
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

  /// Construit la section des dates de péremption
  Widget _buildExpirationDatesSection(Product product) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ExpirationDatesListWidget(
          produitId: product.id,
          gestionPeremption: product.gestionPeremption,
        ),
      ),
    );
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Affiche la boîte de dialogue de suppression
  void _showDeleteDialog(Product product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le produit "${product.nom}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Implémenter la suppression
              Get.snackbar(
                'Suppression',
                'Fonctionnalité à implémenter',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  /// Duplique un produit
  void _duplicateProduct(Product product) {
    Get.toNamed('/products/create', arguments: {
      'duplicate': true,
      'product': product,
    });
  }

  /// Construit la vue d'erreur
  Widget _buildErrorView([String? message]) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur'),
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
              message ?? 'Produit non trouvé',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Impossible d\'afficher les détails du produit.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed('/products'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour aux produits'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la vue de chargement
  Widget _buildLoadingView([String? productId]) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chargement...'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Chargement du produit${productId != null ? ' $productId' : ''}...'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
