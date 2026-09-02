# Correction des mouvements de stock lors des transferts

## Problèmes identifiés

1. **Mouvements de stock sans boutiqueId** : Les mouvements créés lors des transferts n'étaient pas associés à une boutique spécifique
2. **Quantité initiale incorrecte** : L'affichage montrait `-3` au lieu du stock avant/après le mouvement
3. **Mouvement manquant dans la boutique destination** : Le mouvement n'était pas visible car non associé à la boutique

## Corrections apportées

### 1. Backend - Route de transfert (`backend/src/routes/boutiques.js`)

**Ajout du champ `boutiqueId` lors de la création des mouvements de stock :**

```javascript
// Mouvement stock sortie (source)
await tx.mouvementStock.create({
  data: {
    produitId: prdId,
    boutiqueId: srcId,  // ✅ AJOUTÉ
    typeMouvement: 'TRANSFERT_SORTIE',
    changementQuantite: -qty,
    typeReference: 'transfert',
    notes: `Transfert vers boutique #${dstId}${notes ? ' - ' + notes : ''}`
  }
});

// Mouvement stock entrée (destination)
await tx.mouvementStock.create({
  data: {
    produitId: prdId,
    boutiqueId: dstId,  // ✅ AJOUTÉ
    typeMouvement: 'TRANSFERT_ENTREE',
    changementQuantite: qty,
    typeReference: 'transfert',
    notes: `Transfert depuis boutique #${srcId}${notes ? ' - ' + notes : ''}`
  }
});
```

### 2. Backend - Route GET /movements (`backend/src/routes/inventory.js`)

**Inclusion des informations de boutique dans la réponse :**

```javascript
options.include = { 
  produit: {
    include: {
      stock: true,
      stocksBoutiques: boutiqueId ? {
        where: { boutiqueId }
      } : true  // ✅ MODIFIÉ : inclure tous les stocks boutiques
    }
  },
  boutique: true  // ✅ MODIFIÉ : toujours inclure la boutique
};
```

### 3. Backend - DTO (`backend/src/dto/index.js`)

**Ajout des stocksBoutiques dans le DTO du produit :**

```javascript
this.produit = {
  id: mouvement.produit.id,
  reference: mouvement.produit.reference,
  nom: mouvement.produit.nom,
  stockActuel,
  stocksBoutiques: mouvement.produit.stocksBoutiques?.map(sb => ({  // ✅ AJOUTÉ
    boutiqueId: sb.boutiqueId,
    produitId: sb.produitId,
    quantiteDisponible: sb.quantiteDisponible,
    quantiteReservee: sb.quantiteReservee
  }))
};
```

### 4. Frontend - Modèle StockMovement (`logesco_v2/lib/features/inventory/models/stock_model.dart`)

**Ajout du champ `boutiqueId` :**

```dart
class StockMovement {
  final int id;
  final int produitId;
  final int? boutiqueId;  // ✅ AJOUTÉ
  // ... autres champs
}
```

**Création de la classe `StockBoutique` :**

```dart
class StockBoutique {
  final int boutiqueId;
  final int produitId;
  final int quantiteDisponible;
  final int quantiteReservee;
  // ... constructeur et méthodes
}
```

**Ajout du champ `stocksBoutiques` au modèle Product :**

```dart
class Product {
  final int id;
  final String reference;
  final String nom;
  final int seuilStockMinimum;
  final bool? estActif;
  final int? stockActuel;
  final List<StockBoutique>? stocksBoutiques;  // ✅ AJOUTÉ
  // ... constructeur et méthodes
}
```

### 5. Frontend - Affichage des mouvements (`logesco_v2/lib/features/inventory/widgets/stock_movements_getx_view.dart`)

**Correction du calcul du stock pour utiliser le stock de la boutique spécifique :**

```dart
Widget _buildMovementItem(StockMovement movement) {
  final isPositive = movement.changementQuantite > 0;
  final typeColor = _getTypeColor(movement.typeMouvement);

  // Obtenir le stock actuel de la boutique concernée
  int stockActuel = 0;
  if (movement.boutiqueId != null && movement.produit?.stocksBoutiques != null) {
    // Chercher le stock de la boutique spécifique
    final stockBoutique = movement.produit!.stocksBoutiques!.firstWhereOrNull(
      (s) => s.boutiqueId == movement.boutiqueId
    );
    stockActuel = stockBoutique?.quantiteDisponible ?? 0;
  } else {
    // Utiliser le stock global si pas de boutique spécifique
    stockActuel = movement.produit?.stockActuel ?? 0;
  }

  final stockInitial = stockActuel - movement.changementQuantite;
  final stockFinal = stockActuel;
  // ...
}
```

## Résultat attendu

Après ces corrections :

1. ✅ Les mouvements de stock sont correctement associés à leur boutique
2. ✅ Le mouvement de sortie apparaît dans la boutique source avec le bon stock
3. ✅ Le mouvement d'entrée apparaît dans la boutique destination
4. ✅ L'affichage montre correctement : `Stock: [avant] → [changement] → [après]`

## Tests à effectuer

1. Effectuer un transfert de stock entre deux boutiques
2. Vérifier dans la boutique source :
   - Le mouvement de type "TRANSFERT_SORTIE" est visible
   - La quantité est négative (ex: -3)
   - Le stock avant/après est correct
3. Vérifier dans la boutique destination :
   - Le mouvement de type "TRANSFERT_ENTREE" est visible
   - La quantité est positive (ex: +3)
   - Le stock avant/après est correct
