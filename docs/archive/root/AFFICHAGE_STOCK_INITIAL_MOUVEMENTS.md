# Affichage du Stock Initial dans les Mouvements de Stock

## Objectif
Afficher le stock initial (avant le mouvement) pour chaque mouvement de stock, permettant de visualiser la progression: Stock Initial → Changement → Stock Final.

## Modifications Effectuées

### 1. Backend (Déjà en place)

#### `backend/src/dto/index.js`
- Le `MouvementStockDTO` inclut déjà `stockActuel` du produit:
```javascript
if (mouvement.produit) {
  this.produit = {
    id: mouvement.produit.id,
    reference: mouvement.produit.reference,
    nom: mouvement.produit.nom,
    stockActuel: mouvement.produit.stock?.quantiteDisponible
  };
}
```

#### `backend/src/routes/inventory.js`
- La route `/movements` inclut déjà le stock dans la relation produit:
```javascript
options.include = { 
  produit: {
    include: {
      stock: true
    }
  }
};
```

### 2. Frontend Flutter

#### `logesco_v2/lib/features/inventory/models/stock_model.dart`
Ajout du champ `stockActuel` dans la classe `Product`:
```dart
class Product {
  final int id;
  final String reference;
  final String nom;
  final int seuilStockMinimum;
  final bool? estActif;
  final int? stockActuel;  // ✅ NOUVEAU

  Product({
    required this.id,
    required this.reference,
    required this.nom,
    required this.seuilStockMinimum,
    this.estActif,
    this.stockActuel,  // ✅ NOUVEAU
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _safeExtractInt(json, ['id']),
      reference: json['reference'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      seuilStockMinimum: _safeExtractInt(json, ['seuilStockMinimum', 'seuil_stock_minimum', 'minStockLevel']),
      estActif: json['estActif'] as bool?,
      stockActuel: _safeExtractInt(json, ['stockActuel', 'stock_actuel']),  // ✅ NOUVEAU
    );
  }
}
```

#### `logesco_v2/lib/features/inventory/widgets/stock_movements_getx_view.dart`
Modification de `_buildMovementItem()` pour afficher le stock initial → changement → stock final:

```dart
Widget _buildMovementItem(StockMovement movement) {
  final isPositive = movement.changementQuantite > 0;
  final typeColor = _getTypeColor(movement.typeMouvement);
  
  // ✅ Calculer le stock initial et final
  final stockActuel = movement.produit?.stockActuel ?? 0;
  final stockInitial = stockActuel - movement.changementQuantite;
  final stockFinal = stockActuel;

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ListTile(
      // ... autres widgets ...
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (movement.produit?.reference != null) 
            Text('Réf: ${movement.produit!.reference}'),
          Text('Type: ${_getTypeLabel(movement.typeMouvement)}'),
          Text('Date: ${_formatDate(movement.dateMouvement)}'),
          const SizedBox(height: 4),
          // ✅ NOUVEAU: Affichage du stock initial → changement → stock final
          Row(
            children: [
              Text('Stock: ', style: TextStyle(...)),
              Text('$stockInitial', style: TextStyle(...)),
              Icon(Icons.arrow_forward, size: 12),
              Text('${isPositive ? '+' : ''}${movement.changementQuantite}', 
                   style: TextStyle(color: isPositive ? Colors.green : Colors.red)),
              Icon(Icons.arrow_forward, size: 12),
              Text('$stockFinal', style: TextStyle(color: Colors.blue[700])),
            ],
          ),
          if (movement.notes != null && movement.notes!.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Notes: ${movement.notes}'),
            ),
        ],
      ),
      // ... trailing ...
    ),
  );
}
```

## Logique de Calcul

Pour chaque mouvement de stock:
- **Stock Actuel**: Récupéré depuis `produit.stockActuel` (envoyé par le backend)
- **Stock Initial**: `stockActuel - changementQuantite`
- **Stock Final**: `stockActuel`

### Exemple
Si un mouvement indique:
- `changementQuantite = +50`
- `stockActuel = 150`

Alors:
- Stock Initial = 150 - 50 = 100
- Changement = +50
- Stock Final = 150

Affichage: `Stock: 100 → +50 → 150`

## Affichage Visuel

L'interface affiche maintenant pour chaque mouvement:
```
[Icône] Nom du Produit
        Réf: REF001
        Type: Approvisionnement
        Date: 14/02/2026 13:30
        Stock: 100 → +50 → 150
        Notes: Réception commande #123
```

Avec:
- Stock initial en gris
- Changement en vert (positif) ou rouge (négatif)
- Stock final en bleu
- Flèches pour indiquer la progression

## Fichiers Modifiés

1. ✅ `backend/src/dto/index.js` (déjà modifié)
2. ✅ `backend/src/routes/inventory.js` (déjà modifié)
3. ✅ `logesco_v2/lib/features/inventory/models/stock_model.dart`
4. ✅ `logesco_v2/lib/features/inventory/widgets/stock_movements_getx_view.dart`

## Test

Pour tester la fonctionnalité:
1. Redémarrer l'application Flutter
2. Naviguer vers le module Inventaire
3. Sélectionner l'onglet "Mouvements de stock"
4. Vérifier que chaque mouvement affiche: Stock Initial → Changement → Stock Final

## Statut
✅ **TERMINÉ** - Toutes les modifications ont été appliquées avec succès.
