# Correction du tri et affichage des stocks dans le module de vente

## Problèmes identifiés

1. ✅ Les quantités en stock n'étaient pas correctement affichées dans le module de vente
   - Cause: La méthode `loadStocks()` ne chargeait que la première page (100 produits max)
   - Les produits au-delà de 100 n'avaient pas de stocks chargés
2. ✅ Pas de possibilité de trier les produits dans le module de vente

## Solutions implémentées

### 1. Chargement complet des stocks (CORRECTION PRINCIPALE)

Modification de la méthode `loadStocks()` pour charger TOUTES les pages:
```dart
// Avant: Chargeait seulement 100 produits
final response = await _inventoryService.getStock(limit: 100);

// Après: Charge toutes les pages avec pagination
while (hasMore) {
  final response = await _inventoryService.getStock(page: page, limit: 100);
  // Traitement et passage à la page suivante
  page++;
}
```

### 2. Gestion des produits dans SalesController

### 2. Gestion des produits dans SalesController

Ajout de variables pour gérer les produits localement dans le module de vente:
- `_productsForSale`: Liste locale des produits avec tri et filtrage
- `_productSearchQuery`: Recherche de produits
- `_productSortBy`: Critère de tri (nom, prix, reference, categorie)
- `_productSortAscending`: Ordre de tri (croissant/décroissant)

### 3. Méthodes de tri ajoutées

- `loadProductsForSale()`: Charge les produits depuis ProductController
- `updateProductSearchQuery()`: Met à jour la recherche
- `toggleProductSort()`: Bascule l'ordre de tri
- `setProductSortBy()`: Définit le critère de tri
- `_applySortingToProducts()`: Applique le tri et le filtrage
- `refreshProductsAndStocks()`: Rafraîchit produits et stocks ensemble

### 4. Méthodes de débogage améliorées

- `refreshStocks()`: Affiche un résumé détaillé des stocks chargés
- `debugPrintStocks()`: Affiche tous les stocks en mémoire avec statistiques

### 5. Interface de tri dans ProductSelector

Ajout d'une barre de tri avec:
- Boutons de tri par: Nom, Référence, Prix, Catégorie
- Bouton pour basculer l'ordre (croissant/décroissant)
- Bouton de rafraîchissement unique pour produits et stocks

### 6. Indicateurs visuels

- Message d'avertissement si les stocks ne sont pas chargés
- Bouton de rafraîchissement dans le message d'avertissement
- Affichage du nombre de stocks chargés dans la console


## Fichiers modifiés

1. **logesco_v2/lib/features/sales/controllers/sales_controller.dart**
   - Ajout des variables de gestion des produits
   - Ajout des méthodes de tri et filtrage
   - Chargement des produits au démarrage

2. **logesco_v2/lib/features/sales/widgets/product_selector.dart**
   - Utilisation du SalesController au lieu du ProductController
   - Ajout de la barre de tri
   - Affichage des stocks dans la recherche par code-barre

3. **logesco_v2/lib/features/products/controllers/product_controller.dart**
   - Ajout du tri par catégorie dans la méthode `_applySorting()`

## Comment tester

1. Démarrer l'application
2. Aller dans le module de vente (Nouvelle vente)
3. **Vérifier le chargement des stocks:**
   - Regarder la console pour voir le nombre de stocks chargés
   - Si un message orange apparaît "Stocks non chargés", cliquer sur rafraîchir
4. **Vérifier l'affichage des quantités:**
   - Chaque produit doit afficher sa quantité en stock
   - Les produits avec stock > 0 doivent avoir un badge vert
   - Les produits avec stock = 0 doivent avoir un badge rouge
5. **Tester les différents tris:**
   - Cliquer sur "Nom", "Référence", "Prix", "Catégorie"
   - Vérifier que les produits sont bien triés
6. **Tester l'ordre croissant/décroissant:**
   - Cliquer sur la flèche pour inverser l'ordre
7. **Tester la recherche de produits:**
   - Taper un nom de produit dans la barre de recherche
8. **Tester le rafraîchissement:**
   - Cliquer sur le bouton de rafraîchissement
   - Vérifier dans la console que tous les stocks sont rechargés

## Diagnostic en cas de problème

Si les quantités ne s'affichent toujours pas:

1. **Vérifier dans la console:**
   ```
   🔄 Chargement des stocks...
   📄 Page 1 chargée, X stocks
   📄 Page 2 chargée, X stocks
   ✅ Total stocks chargés: X
   ```

2. **Vérifier le nombre de produits vs stocks:**
   - Si vous avez 150 produits mais seulement 100 stocks chargés
   - C'est que la pagination ne fonctionne pas correctement

3. **Utiliser le débogage:**
   - Ajouter un bouton temporaire qui appelle `salesController.debugPrintStocks()`
   - Cela affichera tous les stocks en mémoire

4. **Vérifier l'API:**
   - L'endpoint `/inventory` doit retourner une pagination
   - Vérifier que `hasNext` est bien géré

## Avantages

- Tri indépendant dans le module de vente
- Affichage correct des stocks
- Interface cohérente avec le module stock
- Meilleure expérience utilisateur lors de la vente
