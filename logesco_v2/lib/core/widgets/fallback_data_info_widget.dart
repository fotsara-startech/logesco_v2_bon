import 'package:flutter/material.dart';

/// Widget d'information pour indiquer l'utilisation des données par défaut
class FallbackDataInfoWidget extends StatelessWidget {
  final String dataType;
  final VoidCallback? onRefresh;
  final bool showRefreshButton;

  const FallbackDataInfoWidget({
    super.key,
    required this.dataType,
    this.onRefresh,
    this.showRefreshButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Données par défaut utilisées',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Les $dataType par défaut sont utilisées. Vérifiez votre connexion.',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (showRefreshButton && onRefresh != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRefresh,
              icon: Icon(
                Icons.refresh,
                color: Colors.amber.shade700,
                size: 20,
              ),
              tooltip: 'Réessayer',
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget d'information spécifique pour les rôles
class RolesFallbackInfoWidget extends StatelessWidget {
  final VoidCallback? onRefresh;

  const RolesFallbackInfoWidget({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FallbackDataInfoWidget(
      dataType: 'rôles',
      onRefresh: onRefresh,
    );
  }
}

/// Widget d'information spécifique pour les catégories
class CategoriesFallbackInfoWidget extends StatelessWidget {
  final VoidCallback? onRefresh;

  const CategoriesFallbackInfoWidget({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FallbackDataInfoWidget(
      dataType: 'catégories',
      onRefresh: onRefresh,
    );
  }
}
