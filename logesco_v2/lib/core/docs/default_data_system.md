# Système de Données par Défaut

## 🎯 Problème résolu

Quand la base de données est reset, les **rôles utilisateurs** et **catégories de dépenses** sont supprimés, causant des dysfonctionnements dans l'application.

## 💡 Solution implémentée

### Approche hybride avec fallback intelligent

1. **Données par défaut dans le code** (`DefaultDataService`)
2. **Service de fallback automatique** (`FallbackDataService`) 
3. **Mixin pour faciliter l'utilisation** (`DefaultDataMixin`)
4. **Widgets d'information** pour avertir l'utilisateur

## 📁 Structure des fichiers

```
lib/core/
├── services/
│   ├── default_data_service.dart      # Données par défaut
│   └── fallback_data_service.dart     # Logique de fallback
├── mixins/
│   └── default_data_mixin.dart        # Mixin pour contrôleurs
├── widgets/
│   └── fallback_data_info_widget.dart # Widgets d'information
└── examples/
    └── default_data_usage_example.dart # Exemple d'utilisation
```

## 🔧 Utilisation

### Dans un contrôleur

```dart
class MonController extends GetxController with DefaultDataMixin {
  
  Future<void> loadData() async {
    // Récupère automatiquement avec fallback
    final roles = await getRoles();
    final categories = await getCategories();
    
    // Ou récupérer des éléments spécifiques
    final adminRole = await getAdminRole();
    final defaultCategory = await getDefaultExpenseCategory();
  }
}
```

### Utilisation directe

```dart
// Récupérer avec fallback automatique
final roles = await FallbackDataService.getRolesWithFallback();
final categories = await FallbackDataService.getCategoriesWithFallback();

// Récupérer uniquement les données par défaut
final defaultRoles = DefaultDataService.getDefaultRoles();
final defaultCategories = DefaultDataService.getDefaultCategories();
```

## 📊 Données par défaut incluses

### Rôles utilisateurs
- **Administrateur** : Tous les privilèges
- **Gérant** : Gestion complète sauf utilisateurs et paramètres
- **Vendeur** : Ventes, rapports, stock limité
- **Caissier** : Ventes uniquement

### Catégories de dépenses
- **Achat de marchandises** (Bleu, shopping_cart)
- **Frais généraux** (Gris, receipt_long)
- **Salaires du personnel** (Vert, people)
- **Maintenance et réparation** (Orange, build)
- **Transport et livraison** (Violet, local_shipping)
- **Autres dépenses** (Rouge, more_horiz)

## 🚀 Avantages

✅ **Toujours fonctionnel** : L'app marche même si la BD est vide
✅ **Pas de dépendance externe** : Données dans le code
✅ **Fallback transparent** : Bascule automatique en cas d'erreur
✅ **Versioning** : Données versionnées avec le code
✅ **Cohérence** : Mêmes données sur tous les environnements

## ⚙️ Configuration

L'initialisation se fait automatiquement au démarrage de l'app dans `main.dart` :

```dart
onInit: () async {
  await FallbackDataService.ensureDefaultDataExists();
}
```

## 🔄 Mise à jour des données par défaut

Pour ajouter/modifier les données par défaut :

1. Modifier `DefaultDataService.getDefaultRoles()` ou `getDefaultCategories()`
2. Les changements sont automatiquement disponibles
3. Redémarrer l'app pour appliquer les changements

## 🎨 Interface utilisateur

Quand les données par défaut sont utilisées, un widget d'information s'affiche :

```dart
FallbackDataInfoWidget(
  dataType: 'rôles',
  onRefresh: () => controller.loadData(),
)
```

## 🔍 Debugging

Les logs indiquent quand le fallback est utilisé :
- `✅ Rôles récupérés depuis l'API: X`
- `🔄 Utilisation des rôles par défaut: X`
- `⚠️ Erreur API pour les rôles, utilisation du fallback`