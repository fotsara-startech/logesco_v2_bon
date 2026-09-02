# Guide de gestion des catégories

## Vue d'ensemble

Le système de gestion des catégories permet d'organiser les produits par catégories pour faciliter la navigation et les filtres.

## Fonctionnalités implémentées

### 1. **CategoryController**
- Chargement des catégories depuis l'API
- Sélection/désélection de catégories
- Gestion des états (loading, error)

### 2. **Widgets de catégories**

#### CategorySelector
- Dropdown complet pour sélectionner une catégorie
- Version compacte pour les barres d'outils
- Chip pour afficher la catégorie sélectionnée

#### CategoryStatsCard
- Affiche les statistiques de répartition par catégorie
- Graphiques en barres avec pourcentages
- Tri par nombre de produits

#### ProductFilters
- Interface complète de filtrage
- Combine recherche textuelle et filtrage par catégorie
- Affichage des filtres actifs avec possibilité de les supprimer

### 3. **Page de gestion des catégories**
- Liste des catégories existantes
- Interface pour ajouter/modifier/supprimer des catégories
- Actualisation des données

### 4. **API Endpoints**

#### GET /api/v1/products/categories
Récupère la liste des catégories disponibles.

**Réponse :**
```json
{
  "success": true,
  "data": ["Smartphones", "Ordinateurs", "Accessoires", "Écrans"]
}
```

#### GET /api/v1/products?categorie=Smartphones
Filtre les produits par catégorie.

## Utilisation

### Dans un contrôleur
```dart
final categoryController = Get.find<CategoryController>();

// Charger les catégories
await categoryController.loadCategories();

// Sélectionner une catégorie
categoryController.selectCategory('Smartphones');

// Effacer la sélection
categoryController.clearSelection();
```

### Dans une vue
```dart
// Sélecteur de catégorie simple
const CategorySelector()

// Version compacte
const CompactCategorySelector()

// Chip de catégorie sélectionnée
const CategoryChip()

// Statistiques des catégories
const CategoryStatsCard()

// Interface de filtres complète
const ProductFilters()
```

### Navigation vers la gestion des catégories
```dart
Get.toNamed('/products/categories');
```

## Données de test

Le serveur de test inclut des produits avec les catégories suivantes :
- **Smartphones** : iPhone 15 Pro, Samsung Galaxy S24
- **Ordinateurs** : MacBook Air M3
- **Accessoires** : Souris Logitech, Clavier Corsair
- **Écrans** : Écran Dell 27 pouces

## Intégration avec les produits

Le `ProductController` intègre automatiquement la gestion des catégories :
- Chargement des catégories au démarrage
- Filtrage des produits par catégorie sélectionnée
- Option "Toutes" pour voir tous les produits

## Prochaines étapes

Les fonctionnalités suivantes peuvent être ajoutées :
1. **CRUD des catégories** : Endpoints API pour créer/modifier/supprimer
2. **Hiérarchie de catégories** : Support des sous-catégories
3. **Images de catégories** : Icônes ou images pour chaque catégorie
4. **Statistiques avancées** : Valeur totale par catégorie, tendances
5. **Import/Export** : Gestion en lot des catégories