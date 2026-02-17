import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget d'état vide générique
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.iconColor,
    this.iconSize = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? Get.theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Get.textTheme.headlineSmall?.copyWith(
                color: Get.theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État vide pour les produits
class EmptyProductsState extends StatelessWidget {
  final VoidCallback? onAddProduct;

  const EmptyProductsState({
    super.key,
    this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Aucun produit',
      subtitle: 'Commencez par ajouter vos premiers produits pour gérer votre inventaire.',
      actionText: onAddProduct != null ? 'Ajouter un produit' : null,
      onAction: onAddProduct,
    );
  }
}

/// État vide pour les ventes
class EmptySalesState extends StatelessWidget {
  final VoidCallback? onCreateSale;

  const EmptySalesState({
    super.key,
    this.onCreateSale,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.point_of_sale_outlined,
      title: 'Aucune vente',
      subtitle: 'Aucune vente n\'a été enregistrée pour le moment.',
      actionText: onCreateSale != null ? 'Nouvelle vente' : null,
      onAction: onCreateSale,
    );
  }
}

/// État vide pour les clients
class EmptyCustomersState extends StatelessWidget {
  final VoidCallback? onAddCustomer;

  const EmptyCustomersState({
    super.key,
    this.onAddCustomer,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.people_outline,
      title: 'Aucun client',
      subtitle: 'Ajoutez vos clients pour faciliter la gestion des ventes.',
      actionText: onAddCustomer != null ? 'Ajouter un client' : null,
      onAction: onAddCustomer,
    );
  }
}

/// État vide pour les fournisseurs
class EmptySuppliersState extends StatelessWidget {
  final VoidCallback? onAddSupplier;

  const EmptySuppliersState({
    super.key,
    this.onAddSupplier,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.business_outlined,
      title: 'Aucun fournisseur',
      subtitle: 'Ajoutez vos fournisseurs pour gérer vos approvisionnements.',
      actionText: onAddSupplier != null ? 'Ajouter un fournisseur' : null,
      onAction: onAddSupplier,
    );
  }
}

/// État vide pour les mouvements financiers
class EmptyFinancialMovementsState extends StatelessWidget {
  final VoidCallback? onAddMovement;

  const EmptyFinancialMovementsState({
    super.key,
    this.onAddMovement,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Aucun mouvement',
      subtitle: 'Aucun mouvement financier n\'a été enregistré.',
      actionText: onAddMovement != null ? 'Ajouter un mouvement' : null,
      onAction: onAddMovement,
    );
  }
}

/// État vide pour les résultats de recherche
class EmptySearchState extends StatelessWidget {
  final String searchTerm;
  final VoidCallback? onClearSearch;

  const EmptySearchState({
    super.key,
    required this.searchTerm,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_outlined,
      title: 'Aucun résultat',
      subtitle: 'Aucun résultat trouvé pour "$searchTerm".\nEssayez avec d\'autres mots-clés.',
      actionText: onClearSearch != null ? 'Effacer la recherche' : null,
      onAction: onClearSearch,
    );
  }
}

/// État d'erreur générique
class ErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Get.theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Get.textTheme.headlineSmall?.copyWith(
                color: Get.theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.theme.colorScheme.error,
                  foregroundColor: Get.theme.colorScheme.onError,
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État d'erreur réseau
class NetworkErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorState({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.wifi_off_outlined,
      title: 'Erreur de connexion',
      subtitle: 'Vérifiez votre connexion internet et réessayez.',
      actionText: onRetry != null ? 'Réessayer' : null,
      onAction: onRetry,
    );
  }
}

/// État d'erreur serveur
class ServerErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorState({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.cloud_off_outlined,
      title: 'Erreur serveur',
      subtitle: 'Une erreur s\'est produite sur le serveur. Veuillez réessayer plus tard.',
      actionText: onRetry != null ? 'Réessayer' : null,
      onAction: onRetry,
    );
  }
}

/// État d'accès refusé
class AccessDeniedState extends StatelessWidget {
  final VoidCallback? onGoBack;

  const AccessDeniedState({
    super.key,
    this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.lock_outline,
      title: 'Accès refusé',
      subtitle: 'Vous n\'avez pas les permissions nécessaires pour accéder à cette section.',
      actionText: onGoBack != null ? 'Retour' : null,
      onAction: onGoBack,
    );
  }
}

/// Widget d'état conditionnel
class ConditionalState extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final bool isEmpty;
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;

  const ConditionalState({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.isEmpty,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return errorWidget ?? const NetworkErrorState();
    }

    if (isEmpty) {
      return emptyWidget ??
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Aucune donnée',
            subtitle: 'Aucune donnée disponible pour le moment.',
          );
    }

    return child;
  }
}
