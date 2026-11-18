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
      title: 'sales_no_products'.tr,
      subtitle: 'shared_commencez_par_ajouter_vos_premiers_produits'.tr,
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
      title: 'sales_no_sales'.tr,
      subtitle: 'shared_aucune_vente_n_ete_enregistree_moment'.tr,
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
      title: 'shared_aucun_client'.tr,
      subtitle: 'shared_ajoutez_vos_clients_faciliter_gestion_ventes'.tr,
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
      title: 'suppliers_no_suppliers'.tr,
      subtitle: 'shared_ajoutez_vos_fournisseurs_gerer_vos_approvisionnements'.tr,
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
      title: 'shared_aucun_mouvement'.tr,
      subtitle: 'shared_aucun_mouvement_financier_n_ete_enregistre'.tr,
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
      title: 'no_results'.tr,
      subtitle: 'shared_aucun_resultat_trouve_nessayez_avec_autres'.trParams({'searchTerm': '${searchTerm}'}),
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
      title: 'shared_erreur_connexion'.tr,
      subtitle: 'shared_verifiez_votre_connexion_internet_reessayez'.tr,
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
      title: 'error_server'.tr,
      subtitle: 'shared_erreur_s_est_produite_sur_serveur'.tr,
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
      title: 'suppliers_access_denied'.tr,
      subtitle: 'shared_vous_n_avez_pas_permissions_necessaires'.tr,
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
          EmptyState(
            icon: Icons.inbox_outlined,
            title: 'no_data'.tr,
            subtitle: 'shared_aucune_donnee_disponible_moment'.tr,
          );
    }

    return child;
  }
}
