import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/supplier.dart';

/// Widget de carte pour afficher un fournisseur dans la liste
class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;

  const SupplierCard({
    super.key,
    required this.supplier,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onCall,
    this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et actions
              Row(
                children: [
                  // Icône du fournisseur
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.business,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nom et personne de contact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.nom,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (supplier.personneContact != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            supplier.personneContact!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Menu d'actions
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: const Icon(Icons.edit, size: 20),
                          title: Text('suppliers_edit'.tr),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red, size: 20),
                          title: Text('suppliers_delete'.tr, style: const TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informations de contact
              Row(
                children: [
                  // Téléphone
                  if (supplier.telephone != null) ...[
                    Expanded(
                      child: _buildContactInfo(
                        icon: Icons.phone,
                        text: supplier.telephone!,
                        onTap: onCall,
                      ),
                    ),
                  ],

                  // Email
                  if (supplier.email != null) ...[
                    if (supplier.telephone != null) const SizedBox(width: 12),
                    Expanded(
                      child: _buildContactInfo(
                        icon: Icons.email,
                        text: supplier.email!,
                        onTap: onEmail,
                      ),
                    ),
                  ],
                ],
              ),

              // Adresse si disponible
              if (supplier.adresse != null) ...[
                const SizedBox(height: 8),
                _buildContactInfo(
                  icon: Icons.location_on,
                  text: supplier.adresse!,
                  maxLines: 2,
                ),
              ],

              const SizedBox(height: 8),

              // Informations de date
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'suppliers_created_on'.trParams({'date': _formatDate(supplier.dateCreation)}),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (supplier.dateModification != supplier.dateCreation) ...[
                    const SizedBox(width: 12),
                    Text(
                      '• ${'suppliers_updated_on'.trParams({'date': _formatDate(supplier.dateModification)})}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit une information de contact
  Widget _buildContactInfo({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: onTap != null ? Colors.blue.shade600 : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: onTap != null ? Colors.blue.shade600 : Colors.grey[700],
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
