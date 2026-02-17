# Contrôles d'accès par abonnement - Guide d'intégration

Ce document explique comment intégrer les contrôles d'accès basés sur l'abonnement dans l'application LOGESCO v2.

## Vue d'ensemble

Le système de contrôles d'accès permet de :
- Vérifier automatiquement les licences sur les routes
- Bloquer l'accès aux fonctionnalités expirées
- Afficher des notifications d'expiration
- Gérer les modes dégradés et les périodes de grâce
- Rediriger automatiquement vers l'activation

## Composants principaux

### 1. Middleware de subscription

#### SubscriptionMiddleware
Vérifie automatiquement les licences sur les routes protégées.

```dart
// Dans app_pages.dart
GetPage(
  name: AppRoutes.dashboard,
  page: () => const DashboardPage(),
  middlewares: [SubscriptionMiddleware()],
),
```

#### PremiumFeatureMiddleware
Pour les fonctionnalités premium spécifiques.

```dart
GetPage(
  name: AppRoutes.advancedReports,
  page: () => const AdvancedReportsPage(),
  middlewares: [PremiumFeatureMiddleware()],
),
```

### 2. Widgets de protection

#### SubscriptionGuard
Protège l'accès à un widget entier.

```dart
SubscriptionGuard(
  requireActiveSubscription: true,
  allowGracePeriod: false,
  child: MyProtectedWidget(),
)
```

#### SubscriptionProtectedAction
Protège des actions spécifiques.

```dart
SubscriptionProtectedAction(
  requireActiveSubscription: true,
  onPressed: () => performAction(),
  child: ElevatedButton(
    child: Text('Action Premium'),
  ),
)
```

#### DegradedModeWrapper
Affiche une bannière en mode dégradé.

```dart
DegradedModeWrapper(
  allowModifications: false,
  restrictionMessage: 'Fonctionnalités limitées',
  child: MyWidget(),
)
```

### 3. Widgets d'affichage du statut

#### SubscriptionStatusWidget
Affiche le statut d'abonnement complet.

```dart
// Version complète
SubscriptionStatusWidget()

// Version compacte
SubscriptionStatusWidget(compact: true, showDetails: false)
```

#### SubscriptionAppBarWidget
Pour l'app bar.

```dart
AppBar(
  title: Text('Mon App'),
  actions: [
    SubscriptionAppBarWidget(),
  ],
)
```

#### SubscriptionNotificationBanner
Bannière de notification critique.

```dart
Column(
  children: [
    SubscriptionNotificationBanner(),
    // Contenu principal
  ],
)
```

### 4. Mixin pour les pages

#### SubscriptionAwarePage
Ajoute des méthodes utilitaires aux pages.

```dart
class MyPage extends StatefulWidget {
  // ...
}

class _MyPageState extends State<MyPage> with SubscriptionAwarePage {
  void _performAction() {
    if (canPerformAction(requireActiveSubscription: true)) {
      // Action autorisée
    } else {
      showRestrictionMessage();
    }
  }
}
```

## Intégration dans les pages existantes

### 1. Pages principales (Dashboard, etc.)

```dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          SubscriptionAppBarWidget(), // Statut compact
        ],
      ),
      body: Column(
        children: [
          SubscriptionNotificationBanner(), // Notifications critiques
          SubscriptionStatusWidget(showDetails: false), // Statut
          Expanded(
            child: DegradedModeWrapper(
              child: _buildDashboardContent(),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 2. Pages de fonctionnalités

```dart
class ProductsPage extends StatefulWidget {
  // ...
}

class _ProductsPageState extends State<ProductsPage> with SubscriptionAwarePage {
  @override
  Widget build(BuildContext context) {
    return SubscriptionGuard(
      requireActiveSubscription: false, // Permet la consultation
      allowGracePeriod: true,
      child: Scaffold(
        body: DegradedModeWrapper(
          allowModifications: false, // Bloque les modifications
          child: _buildProductsList(),
        ),
        floatingActionButton: Obx(() {
          final canAdd = canPerformAction(requireActiveSubscription: true);
          return FloatingActionButton(
            onPressed: canAdd ? _addProduct : null,
            child: Icon(Icons.add),
          );
        }),
      ),
    );
  }
}
```

### 3. Formulaires et actions

```dart
class ProductFormPage extends StatefulWidget {
  // ...
}

class _ProductFormPageState extends State<ProductFormPage> with SubscriptionAwarePage {
  @override
  Widget build(BuildContext context) {
    return SubscriptionGuard(
      requireActiveSubscription: true, // Nécessite un abonnement actif
      child: Scaffold(
        appBar: AppBar(title: Text('Nouveau produit')),
        body: _buildForm(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SubscriptionProtectedAction(
      requireActiveSubscription: true,
      onPressed: _saveProduct,
      child: ElevatedButton(
        child: Text('Sauvegarder'),
      ),
    );
  }
}
```

## Configuration des routes

### Routes avec middleware

```dart
// Routes principales avec vérification d'abonnement
GetPage(
  name: AppRoutes.dashboard,
  page: () => const DashboardPage(),
  middlewares: [SubscriptionMiddleware()],
),

// Routes premium
GetPage(
  name: AppRoutes.advancedReports,
  page: () => const AdvancedReportsPage(),
  middlewares: [PremiumFeatureMiddleware()],
),

// Routes d'abonnement (exemptées)
GetPage(
  name: AppRoutes.subscriptionActivation,
  page: () => const LicenseActivationPage(),
  // Pas de middleware
),
```

### Routes exemptées

Les routes suivantes sont automatiquement exemptées :
- `/login`
- `/splash`
- `/subscription/activation`
- `/subscription/status`
- `/subscription/blocked`

## Gestion des erreurs et cas particuliers

### 1. Erreurs de licence

```dart
try {
  final controller = Get.find<SubscriptionController>();
  await controller.refreshStatus();
} catch (e) {
  // Redirection automatique vers l'activation
}
```

### 2. Mode hors ligne

Le système fonctionne en mode hors ligne avec les données mises en cache.

### 3. Période de grâce

```dart
SubscriptionGuard(
  allowGracePeriod: true, // Autorise l'accès en période de grâce
  child: MyWidget(),
)
```

## Personnalisation

### Messages personnalisés

```dart
SubscriptionProtectedAction(
  restrictionMessage: 'Cette fonctionnalité avancée nécessite un abonnement Pro',
  child: MyButton(),
)
```

### Styles personnalisés

Les widgets utilisent le thème de l'application et peuvent être personnalisés via les couleurs du thème.

## Bonnes pratiques

1. **Utilisez les middlewares** pour les routes principales
2. **Combinez les widgets** pour une protection complète
3. **Gérez la période de grâce** selon les besoins métier
4. **Affichez des messages clairs** à l'utilisateur
5. **Testez les différents états** d'abonnement

## Exemple complet

Voir le fichier `access_control_integration_example.dart` pour des exemples complets d'intégration.