# Correction critique : Enregistrement du stock initial/final dans les mouvements

## Problème identifié

Les mouvements de stock n'enregistrent pas le **snapshot du stock avant/après** le mouvement. 
Cela rend impossible l'affichage correct de l'historique.

Actuellement affiché (incorrect) : 
```
Type: Achat, Stock: 0 +8 +8
Type: Vente, Stock: 9 -1 +8
```

Devrait être (correct) :
```
Type: Achat, Stock: 0 → +8 → 8
Type: Vente, Stock: 9 → -1 → 8
```

## Changements appliqués

### 1. ✅ Schéma Prisma (backend/prisma/schema.prisma)
- Ajout de `stockInitial` et `stockFinal` au modèle `MouvementStock`

### 2. ✅ Migration SQL (backend/prisma/migrations/add_stock_snapshots.sql)
- Création des colonnes dans la base de données

### 3. ✅ DTO (backend/src/dto/index.js)
- Mise à jour de `MouvementStockDTO` pour inclure les snapshots

### 4. ❌ Routes à mettre à jour
Les routes suivantes doivent être mises à jour pour enregistrer `stockInitial` et `stockFinal` :

#### Routes principales :
1. `backend/src/routes/inventory.js` - POST `/movements` (ligne 752)
2. `backend/src/routes/sales.js` - POST `/sales` (ligne 890)
3. `backend/src/routes/sales.js` - POST `/sales/:id/cancel` (ligne 1528)
4. `backend/src/routes/procurement.js` - POST `/commandes` (ligne 696)
5. `backend/src/routes/boutiques.js` - POST `/transfer` (lignes 328, 340)
6. `backend/src/routes/stock-inventory.js` - POST `/count` (ligne 407)
7. `backend/src/models/index.js` - Transactions diverses

## Étapes de fix

Pour chaque création de mouvement, avant le `.create()`, récupérer le stock actuel :

```javascript
// 1. Récupérer le stock actuel AVANT le mouvement
const stockActuel = await tx.stock.findUnique({
  where: { id: produitId },
  select: { quantiteDisponible: true }
});
const stockInitial = stockActuel?.quantiteDisponible || 0;

// 2. Créer le mouvement AVEC snapshots
await tx.mouvementStock.create({
  data: {
    produitId,
    typeMouvement,
    changementQuantite,
    stockInitial,
    stockFinal: stockInitial + changementQuantite, // ← Le nouveau stock après mouvement
    // ... autres champs
  }
});
```

**Note**: Il faut s'assurer que le stock a déjà été mis à jour ou calculer `stockFinal` correctement basé sur la nouvelle valeur.

## Priorisation

1. **Critique** : Routes de vente (sales.js) - impactent directement les mouvements
2. **Important** : Routes d'approvisionnement (procurement.js) - impacts secondaires
3. **Moyen** : Autres routes

## Pour les mouvements historiques

Les anciens mouvements sans snapshots peuvent être recalculés avec une migration de données, mais ce n'est pas critique pour fonctionnel immédiat.

## Frontend (Dart)

Mise à jour du widget `stock_movements_getx_view.dart` pour utiliser les snapshots :

```dart
final stockInitial = movement.stockInitial; // Au lieu de calculer
final stockFinal = movement.stockFinal;     // Au lieu de calculer

// Affichage correct :
Text('Stock: $stockInitial → ${movement.changementQuantite} → $stockFinal')
```

