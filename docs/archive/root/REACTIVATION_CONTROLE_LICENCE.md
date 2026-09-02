# Guide de Réactivation du Contrôle de Licence

## Vue d'ensemble

Ce guide explique comment réactiver le contrôle de licence une fois que les problèmes d'activation sont résolus.

## Fichiers à Restaurer

### 1. logesco_v2/lib/core/services/app_initialization_service.dart

**Restaurer la méthode `_startPeriodicSubscriptionChecks`:**

```dart
/// Démarre les vérifications périodiques d'abonnement
void _startPeriodicSubscriptionChecks(SubscriptionController controller) {
  // Vérification toutes les 30 minutes
  Timer.periodic(const Duration(minutes: 30), (timer) async {
    try {
      print('🔄 [AppInit] Vérification périodique d\'abonnement...');
      await controller.forceValidation();

      // Vérifier si l'application doit être bloquée
      final shouldBlock = await controller.shouldBlockApplication();
      if (shouldBlock) {
        print('🚫 [AppInit] Application bloquée - redirection vers activation');
        Get.offAllNamed('/subscription/blocked');
      }
    } catch (e) {
      print('⚠️ [AppInit] Erreur lors de la vérification périodique: $e');
    }
  });
}
```

### 2. logesco_v2/lib/features/subscription/services/implementations/subscription_manager.dart

**Restaurer la méthode `shouldBlockApplication`:**

```dart
@override
Future<bool> shouldBlockApplication() async {
  const cacheKey = 'should_block_application';

  // Vérifier le cache rapide pour cette vérification critique
  if (_isValidCacheEntry(cacheKey, _fastCacheValiditySeconds)) {
    return _validationCache[cacheKey] as bool;
  }

  try {
    final status = await getCurrentStatus();

    bool shouldBlock = true;

    // Ne pas bloquer si l'abonnement est actif
    if (status.isActive) {
      shouldBlock = false;
    }
    // Vérifier la période de grâce
    else if (status.isInGracePeriod) {
      shouldBlock = false;
    }
    // Bloquer si aucun abonnement actif et pas de période de grâce
    else {
      shouldBlock = true;
    }

    // Mettre en cache le résultat
    _setCacheEntry(cacheKey, shouldBlock);

    return shouldBlock;
  } catch (e) {
    // En cas d'erreur, bloquer par sécurité mais ne pas mettre en cache
    print('❌ [SubscriptionManager] Erreur shouldBlockApplication: $e');
    return true;
  }
}
```

### 3. logesco_v2/lib/features/subscription/mixins/subscription_verification_mixin.dart

**Restaurer la méthode `verifySubscriptionForAction`:**

```dart
/// Vérifie si l'abonnement est actif avant d'exécuter une action
Future<bool> verifySubscriptionForAction({
  bool requireActiveSubscription = true,
  bool allowGracePeriod = false,
  String? actionName,
}) async {
  try {
    final status = subscriptionController.currentStatus;

    // Si pas de statut disponible, bloquer par sécurité
    if (status == null) {
      _showSubscriptionError(
        'Statut d\'abonnement non disponible',
        'Impossible de vérifier votre abonnement. Veuillez réessayer.',
      );
      return false;
    }

    // Si l'abonnement est complètement expiré
    if (!status.isActive && !status.isInGracePeriod) {
      _showSubscriptionError(
        'Abonnement expiré',
        actionName != null ? 'L\'action "$actionName" nécessite un abonnement actif.' : 'Cette action nécessite un abonnement actif.',
      );
      return false;
    }

    // Si en période de grâce et que ce n'est pas autorisé
    if (status.isInGracePeriod && !allowGracePeriod && requireActiveSubscription) {
      _showSubscriptionError(
        'Période de grâce',
        actionName != null ? 'L\'action "$actionName" n\'est pas autorisée en période de grâce.' : 'Cette action n\'est pas autorisée en période de grâce.',
      );
      return false;
    }

    // Vérifier si l'application doit être bloquée
    final shouldBlock = await subscriptionController.shouldBlockApplication();
    if (shouldBlock) {
      _showSubscriptionError(
        'Accès bloqué',
        'L\'application est temporairement bloquée. Activez une licence pour continuer.',
      );
      return false;
    }

    return true;
  } catch (e) {
    print('❌ [SubscriptionVerification] Erreur lors de la vérification: $e');
    _showSubscriptionError(
      'Erreur de vérification',
      'Impossible de vérifier votre abonnement. Veuillez réessayer.',
    );
    return false;
  }
}
```

### 4. logesco_v2/lib/features/subscription/services/notification_service.dart

**Restaurer la méthode `shouldBlockApplication`:**

```dart
/// Vérifie si l'application doit être bloquée
static bool shouldBlockApplication(SubscriptionStatus? status) {
  if (status == null) return true;

  // Bloquer si l'abonnement est expiré et pas en période de grâce
  return !status.isActive && !status.isInGracePeriod;
}
```

### 5. logesco_v2/lib/features/subscription/widgets/subscription_guard.dart

**Restaurer la méthode `build` de `SubscriptionGuard`:**

```dart
@override
Widget build(BuildContext context) {
  final subscriptionController = Get.find<SubscriptionController>();

  return Obx(() {
    final status = subscriptionController.currentStatus;

    // Si pas de statut disponible, bloquer par sécurité
    if (status == null) {
      return const SubscriptionBlockedPage();
    }

    // Si l'abonnement est complètement expiré
    if (!status.isActive && !status.isInGracePeriod) {
      return const SubscriptionBlockedPage();
    }

    // Si en période de grâce et que ce n'est pas autorisé
    if (status.isInGracePeriod && !allowGracePeriod && requireActiveSubscription) {
      return const SubscriptionBlockedPage();
    }

    // Si l'abonnement est actif ou en période de grâce autorisée
    if (status.isActive || (status.isInGracePeriod && allowGracePeriod)) {
      // Afficher avec bannière de mode dégradé si nécessaire
      if (status.isInGracePeriod || subscriptionController.isInDegradedMode()) {
        return DegradedModeWrapper(
          allowModifications: !requireActiveSubscription,
          restrictionMessage: restrictionMessage,
          child: child,
        );
      }

      return child;
    }

    // Par défaut, bloquer
    return const SubscriptionBlockedPage();
  });
}
```

**Restaurer la méthode `build` de `SubscriptionProtectedAction`:**

```dart
@override
Widget build(BuildContext context) {
  final subscriptionController = Get.find<SubscriptionController>();

  return Obx(() {
    final status = subscriptionController.currentStatus;
    final canPerformAction = _canPerformAction(status);

    return GestureDetector(
      onTap: canPerformAction ? onPressed : () => _showRestrictionDialog(context),
      child: Opacity(
        opacity: canPerformAction ? 1.0 : 0.6,
        child: child,
      ),
    );
  });
}
```

**Restaurer la méthode `canPerformAction`:**

```dart
bool canPerformAction(SubscriptionStatus? status) {
  if (status == null) return false;

  if (!requireActiveSubscription) {
    // Autoriser si pas de restriction stricte (mode consultation)
    return status.isActive || status.isInGracePeriod;
  }

  // Nécessite un abonnement actif (pas de période de grâce)
  return status.isActive && !status.isInGracePeriod;
}
```

**Restaurer les imports:**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import '../models/subscription_status.dart';
import '../views/subscription_blocked_page.dart';
import '../views/license_activation_page.dart';
import 'degraded_mode_wrapper.dart';
```

## Procédure de Réactivation

1. **Restaurer les fichiers** en utilisant les codes fournis ci-dessus
2. **Vérifier la compilation** : `flutter analyze`
3. **Tester complètement** le système de licence
4. **Vérifier les logs** pour s'assurer que les vérifications fonctionnent
5. **Déployer** la nouvelle version

## Vérification Post-Réactivation

Après réactivation, vérifier que:
- ✅ Les vérifications périodiques s'exécutent
- ✅ L'application se bloque si la licence expire
- ✅ Les notifications d'expiration s'affichent
- ✅ Le mode dégradé fonctionne correctement
- ✅ Les pages d'activation sont accessibles

## Rollback Rapide

Si des problèmes surviennent après réactivation:
1. Restaurer les fichiers modifiés depuis le contrôle de version
2. Redéployer la version avec contrôle désactivé
3. Investiguer les problèmes

## Notes

- La réactivation doit être testée complètement avant déploiement
- Assurez-vous que le système de génération de clés fonctionne correctement
- Documentez tous les changements effectués
