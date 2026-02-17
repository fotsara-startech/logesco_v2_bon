# Tâche 7.3 - Écrans de notification et blocage

## Implémentation complète

Cette tâche implémente les écrans de notification et blocage selon les requirements 1.3, 6.1, 6.2, 6.3, 6.4.

### Composants créés

#### 1. Pop-ups de notification d'expiration (`expiration_notification_dialog.dart`)
- **Requirement 6.1** : Notification 3 jours avant expiration
- **Requirement 6.2** : Notification urgente 1 jour avant expiration
- Dialog adaptatif selon le nombre de jours restants
- Boutons d'action pour activation de licence
- Mode non-dismissible pour les notifications urgentes

#### 2. Écran de blocage (`blocked_page.dart`)
- **Requirement 1.3** : Blocage après expiration
- **Requirement 6.4** : Gestion de la période de grâce de 3 jours
- Interface claire avec informations de statut
- Actions disponibles selon le contexte (période de grâce ou expiration complète)

#### 3. Interface de mode dégradé (`degraded_mode_banner.dart`)
- **Requirement 6.4** : Mode consultation avec accès limité
- Bannière d'information persistante
- Wrapper pour protéger les fonctionnalités
- Overlay de restriction pour les actions non autorisées

#### 4. Service de notification (`notification_service.dart`)
- Gestion automatique des notifications selon le statut
- Contrôle de fréquence d'affichage
- Méthodes utilitaires pour vérifier les restrictions

#### 5. Widgets de protection (`subscription_guard.dart`)
- `SubscriptionGuard` : Protection au niveau page
- `SubscriptionProtectedAction` : Protection au niveau action
- `SubscriptionAwarePage` : Mixin pour les pages sensibles

### Intégration dans le contrôleur

Le `SubscriptionController` a été étendu avec :
- `checkAndShowNotifications()` : Vérification automatique des notifications
- `isInDegradedMode()` : Détection du mode dégradé
- Réinitialisation des compteurs après activation

### Utilisation

#### Protection d'une page complète
```dart
SubscriptionGuard(
  requireActiveSubscription: false,
  allowGracePeriod: true,
  child: MyPage(),
)
```

#### Protection d'une action spécifique
```dart
SubscriptionProtectedAction(
  requireActiveSubscription: true,
  onPressed: () => performAction(),
  child: MyButton(),
)
```

#### Page avec vérifications automatiques
```dart
class MyPage extends StatefulWidget {
  // ...
}

class _MyPageState extends State<MyPage> with SubscriptionAwarePage {
  void onSavePressed() {
    if (canPerformAction(requireActiveSubscription: true)) {
      // Effectuer l'action
    } else {
      showRestrictionMessage();
    }
  }
}
```

### Flux de notification automatique

1. **Au démarrage de l'application** : Vérification du statut
2. **Notifications programmées** :
   - 3 jours avant : Notification d'avertissement (1x/jour)
   - 1 jour avant : Notification urgente (à chaque ouverture)
   - Expiration : Écran de blocage ou période de grâce
3. **Mode dégradé** : Bannière et restrictions automatiques

### Requirements couverts

- ✅ **1.3** : Blocage après expiration avec écran dédié
- ✅ **6.1** : Notification 3 jours avant expiration
- ✅ **6.2** : Notification urgente 1 jour avant expiration  
- ✅ **6.3** : Période de grâce de 3 jours avec mode consultation
- ✅ **6.4** : Interface de mode dégradé avec accès limité

### Exemple d'utilisation

Voir `examples/notification_example.dart` pour une démonstration complète de tous les composants.