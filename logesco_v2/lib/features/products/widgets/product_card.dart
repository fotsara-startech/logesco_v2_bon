import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../../../shared/constants/constants.dart';
import '../../../core/services/permission_service.dart';

/// Carte d'affichage d'un produit dans la liste
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et statut
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nom,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'product_card_reference'.tr.replaceAll('@reference', product.reference),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (product.codeBarre != null && product.codeBarre!.isNotEmpty)
                          Text(
                            'product_card_code'.tr.replaceAll('@code', product.codeBarre!),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                  _buildActionsMenu(context),
                ],
              ),

              const SizedBox(height: 12),

              // Informations principales
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.attach_money,
                      'product_card_sale_price'.tr,
                      CurrencyConstants.formatAmount(product.prixUnitaire),
                    ),
                  ),
                  if (product.prixAchat != null)
                    Expanded(
                      child: _buildInfoItem(
                        Icons.shopping_cart,
                        'product_card_purchase_price'.tr,
                        CurrencyConstants.formatAmount(product.prixAchat!),
                      ),
                    )
                  else if (product.categorie != null && product.categorie!.isNotEmpty)
                    Expanded(
                      child: _buildInfoItem(
                        Icons.category,
                        'product_card_category'.tr,
                        product.categorie!,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  if (!product.estService)
                    Expanded(
                      child: _buildInfoItem(
                        Icons.warning_amber,
                        'product_card_stock_threshold'.tr,
                        'product_card_units'.tr.replaceAll('@count', product.seuilStockMinimum.toString()),
                      ),
                    )
                  else
                    Expanded(
                      child: _buildInfoItem(
                        Icons.design_services,
                        'product_card_type'.tr,
                        'product_card_service'.tr,
                      ),
                    ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.schedule,
                      'product_card_modified'.tr,
                      _formatDate(product.dateModification),
                    ),
                  ),
                ],
              ),

              // Description si disponible
              if (product.description != null && product.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construit le menu d'actions avec permissions
  Widget _buildActionsMenu(BuildContext context) {
    final permissionService = Get.find<PermissionService>();
    final canUpdate = permissionService.hasPermission('products', 'UPDATE');
    final canDelete = permissionService.hasPermission('products', 'DELETE');

    // Si aucune permission, ne pas afficher le menu
    if (!canUpdate && !canDelete) {
      return const SizedBox.shrink();
    }

    final items = <PopupMenuEntry<String>>[];

    // Option Modifier
    if (canUpdate) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: const Icon(Icons.edit),
            title: Text('product_card_edit'.tr),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    // Option Activer/Désactiver
    if (canUpdate) {
      items.add(
        PopupMenuItem(
          value: 'toggle',
          child: ListTile(
            leading: Icon(
              product.estActif ? Icons.visibility_off : Icons.visibility,
            ),
            title: Text(product.estActif ? 'product_card_deactivate'.tr : 'product_card_activate'.tr),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    // Option Supprimer
    if (canDelete) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text('product_card_delete'.tr, style: const TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'toggle':
            onToggleStatus?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => items,
    );
  }

  /// Construit le chip de statut
  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: product.estActif ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            product.estActif ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: product.estActif ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            product.estActif ? 'product_card_active'.tr : 'product_card_inactive'.tr,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: product.estActif ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un élément d'information
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'product_card_today'.tr;
    } else if (difference.inDays == 1) {
      return 'product_card_yesterday'.tr;
    } else if (difference.inDays < 7) {
      return 'product_card_days_ago'.tr.replaceAll('@days', difference.inDays.toString());
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
