# Système de Gestion des États de Chargement

Ce document explique comment utiliser le système amélioré de gestion des états de chargement dans l'application de mouvements financiers.

## Vue d'ensemble

Le système de gestion des états de chargement fournit une approche unifiée pour gérer tous les types d'états de chargement dans l'application, incluant :

- Chargement initial
- Actualisation
- Chargement de plus d'éléments
- Opérations CRUD (création, mise à jour, suppression)
- Export et génération de rapports
- Gestion des erreurs et succès

## Composants principaux

### 1. LoadingState

Modèle qui représente un état de chargement avec contexte :

```dart
class LoadingState {
  final LoadingStateType type;
  final String? message;
  final String? operation;
  final double? progress;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
}
```

### 2. LoadingStateType

Énumération des différents types d'états :

```dart
enum LoadingStateType {
  idle,
  loading,
  refreshing,
  loadingMore,
  creating,
  updating,
  deleting,
  exporting,
  generating,
  error,
  success,
}
```

### 3. LoadingStateMixin

Mixin qui ajoute la gestion des états de chargement aux contrôleurs :

```dart
class MyController extends GetxController with LoadingStateMixin {
  // Votre code ici
}
```

## Utilisation dans les contrôleurs

### Méthodes de base

```dart
// Définir un état de chargement
setLoading(message: 'Chargement des données...', operation: 'loadData');

// Définir un état d'erreur
setError(message: 'Erreur de connexion', operation: 'loadData');

// Définir un état de succès
setSuccess(message: 'Données chargées avec succès', operation: 'loadData');

// Retourner à l'état idle
setIdle();
```

### Exécution avec gestion automatique

```dart
Future<void> loadData() async {
  await executeWithLoadingState<void>(
    () async {
      // Votre logique de chargement ici
      final data = await apiService.getData();
      // Traitement des données
    },
    loadingState: LoadingState.loading(
      message: 'Chargement des données...',
      operation: 'loadData',
    ),
    successMessage: 'Données chargées avec succès',
    errorMessage: 'Erreur lors du chargement',
  );
}
```

### Gestion du progrès

```dart
Future<void> exportData() async {
  setExporting(
    message: 'Export en cours...',
    operation: 'exportData',
    progress: 0.0,
  );
  
  // Simulation du progrès
  for (int i = 0; i <= 100; i += 10) {
    await Future.delayed(Duration(milliseconds: 100));
    updateProgress(i / 100.0, message: 'Export en cours... $i%');
  }
  
  setSuccess(message: 'Export terminé avec succès');
}
```

## Utilisation dans l'interface utilisateur

### LoadingStateWidget

Widget principal pour afficher les états de chargement :

```dart
LoadingStateWidget(
  loadingState: controller.loadingState,
  showProgressBar: true,
  showLoadingMessage: true,
  onRetry: () => controller.loadData(),
  child: YourContentWidget(),
)
```

### LoadingStateBar

Barre compacte pour afficher l'état en haut de l'écran :

```dart
LoadingStateBar(
  loadingState: controller.loadingState,
  showOnlyWhenLoading: true,
)
```

### FloatingLoadingIndicator

Indicateur flottant pour les opérations en arrière-plan :

```dart
Stack(
  children: [
    YourMainContent(),
    FloatingLoadingIndicator(
      loadingState: controller.loadingState,
    ),
  ],
)
```

## Exemple complet

```dart
class MyController extends GetxController with LoadingStateMixin {
  final RxList<Item> items = <Item>[].obs;
  
  Future<void> loadItems() async {
    await executeWithLoadingState<void>(
      () async {
        final response = await apiService.getItems();
        items.value = response.data;
      },
      loadingState: LoadingState.loading(
        message: 'Chargement des éléments...',
        operation: 'loadItems',
      ),
      successMessage: 'Éléments chargés avec succès',
      errorMessage: 'Erreur lors du chargement des éléments',
    );
  }
  
  Future<void> createItem(ItemForm form) async {
    await executeWithLoadingState<void>(
      () async {
        await apiService.createItem(form);
        await loadItems(); // Recharge la liste
      },
      loadingState: LoadingState.creating(
        message: 'Création de l\'élément...',
        operation: 'createItem',
      ),
      successMessage: 'Élément créé avec succès',
      errorMessage: 'Erreur lors de la création',
    );
  }
}
```

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MyController>();
    
    return Scaffold(
      body: Column(
        children: [
          LoadingStateBar(loadingState: controller.loadingState),
          Expanded(
            child: LoadingStateWidget(
              loadingState: controller.loadingState,
              onRetry: () => controller.loadItems(),
              child: Obx(() => ListView.builder(
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(controller.items[index].name),
                  );
                },
              )),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Méthodes de convenance

Les contrôleurs qui utilisent `LoadingStateMixin` ont accès à des méthodes de convenance :

```dart
// Vérifier si une opération est en cours
bool get isAnyLoading;
bool get isInitialLoading;
bool get isCrudOperationInProgress;

// Obtenir des informations sur l'état actuel
String get currentLoadingMessage;
String? get currentOperation;
bool get hasProgress;
int get progressPercentage;

// Vérifier une opération spécifique
bool isOperationInProgress('loadData');
```

## Bonnes pratiques

1. **Utilisez des messages descriptifs** : Fournissez des messages clairs pour informer l'utilisateur
2. **Nommez vos opérations** : Utilisez des noms d'opération cohérents pour le débogage
3. **Gérez les erreurs** : Toujours fournir un message d'erreur approprié
4. **Utilisez le progrès** : Pour les opérations longues, montrez le progrès à l'utilisateur
5. **Réinitialisez l'état** : Assurez-vous de revenir à l'état idle après les opérations

## Personnalisation

Vous pouvez personnaliser l'apparence des widgets de chargement en modifiant les couleurs, les icônes et les messages dans `LoadingStateWidget`.

## Débogage

Pour déboguer les états de chargement, vous pouvez :

1. Utiliser `LoadingStateDemo` pour tester différents états
2. Vérifier les logs avec les noms d'opération
3. Utiliser les métadonnées pour des informations supplémentaires