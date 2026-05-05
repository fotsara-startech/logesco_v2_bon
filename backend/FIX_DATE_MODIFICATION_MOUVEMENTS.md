# Fix: date_modification Manquant dans mouvements_stock

## 🐛 Problème Identifié

Le code de synchronisation essayait d'utiliser un champ `date_modification` qui **n'existe pas** dans la table `mouvements_stock`.

### Erreur

```
Unknown argument `dateModification`. Available options are marked with ?.
```

### Cause

Le modèle Prisma `MouvementStock` n'a que ces champs:
- `id`
- `produitId` → `produit_id`
- `boutiqueId` → `boutique_id`
- `typeMouvement` → `type_mouvement`
- `changementQuantite` → `changement_quantite`
- `referenceId` → `reference_id`
- `typeReference` → `type_reference`
- `dateMouvement` → `date_mouvement` ✅
- `notes`

**Pas de `dateModification` / `date_modification`!**

## ✅ Solution Appliquée

### 1. Correction dans `sales.js`

**Avant** (incorrect):
```javascript
const mouvement = await prisma.mouvementStock.findFirst({
  where: { ... },
  orderBy: { dateModification: 'desc' } // ❌ N'existe pas
});

await syncService.enqueue('mouvements_stock', 'INSERT', {
  // ...
  date_modification: mouvement.dateModification // ❌ N'existe pas
});
```

**Après** (correct):
```javascript
const mouvement = await prisma.mouvementStock.findFirst({
  where: { ... },
  orderBy: { id: 'desc' } // ✅ Utiliser id
});

await syncService.enqueue('mouvements_stock', 'INSERT', {
  // ...
  // date_modification retiré
});
```

### 2. Correction dans `prisma-sync-hooks.js`

**Avant** (incorrect):
```javascript
mouvementStock: {
  table: 'mouvements_stock',
  columns: [
    'id', 'produit_id', 'boutique_id', 'type_mouvement', 
    'changement_quantite', 'reference_id', 'type_reference', 
    'date_mouvement', 'notes', 'date_modification' // ❌ N'existe pas
  ]
}
```

**Après** (correct):
```javascript
mouvementStock: {
  table: 'mouvements_stock',
  columns: [
    'id', 'produit_id', 'boutique_id', 'type_mouvement', 
    'changement_quantite', 'reference_id', 'type_reference', 
    'date_mouvement', 'notes' // ✅ date_modification retiré
  ]
}
```

## 📊 Comparaison des Tables

### mouvements_stock (❌ PAS de date_modification)
```sql
CREATE TABLE mouvements_stock (
  id INTEGER PRIMARY KEY,
  produit_id INTEGER,
  boutique_id INTEGER,
  type_mouvement TEXT,
  changement_quantite INTEGER,
  reference_id INTEGER,
  type_reference TEXT,
  date_mouvement DATETIME DEFAULT CURRENT_TIMESTAMP,
  notes TEXT
  -- PAS de date_modification
);
```

### stock_boutiques (✅ A date_modification)
```sql
CREATE TABLE stock_boutiques (
  id INTEGER PRIMARY KEY,
  boutique_id INTEGER,
  produit_id INTEGER,
  quantite_disponible INTEGER,
  quantite_reservee INTEGER,
  derniere_maj DATETIME,
  date_modification DATETIME DEFAULT CURRENT_TIMESTAMP -- ✅ Existe
);
```

## 🔍 Pourquoi Cette Différence?

La table `mouvements_stock` est une **table d'historique** (append-only):
- Les mouvements sont créés mais jamais modifiés
- Pas besoin de `date_modification` car `date_mouvement` suffit
- Chaque mouvement est un enregistrement immuable

Les tables `stock_boutiques` et `stock` sont des **tables d'état**:
- Les quantités sont mises à jour régulièrement
- `date_modification` permet de tracker les changements
- Nécessaire pour la synchronisation incrémentale

## 🚀 Test

### Redémarrer le Backend

```powershell
cd D:\projects\Logesco_bon\logesco_app\backend
npm start
```

### Créer une Vente

Logs attendus:
```
🔧 [Sync] Début de la synchronisation manuelle...
🔧 [Sync] Traitement produit 881, type: undefined
🔄 [Manual Sync] mouvements_stock trouvé: 640
✅ [Manual Sync] mouvements_stock synchronisé: 640
🔄 [Manual Sync] stock_boutiques trouvé: 122
✅ [Manual Sync] stock_boutiques synchronisé: 122
✅ [Sync] Synchronisation manuelle terminée
📤 Push 3 opération(s) vers Neon...
```

### Vérifier dans Neon

```sql
-- Mouvements de stock récents
SELECT * FROM mouvements_stock 
WHERE date_mouvement > NOW() - INTERVAL '5 minutes'
ORDER BY id DESC;

-- Vérifier que les données sont complètes
SELECT 
  id,
  produit_id,
  type_mouvement,
  changement_quantite,
  date_mouvement
FROM mouvements_stock 
WHERE id = (SELECT MAX(id) FROM mouvements_stock);
```

## 📁 Fichiers Modifiés

1. **`backend/src/routes/sales.js`**
   - Changé `orderBy: { dateModification: 'desc' }` → `orderBy: { id: 'desc' }`
   - Retiré `date_modification` des données de sync

2. **`backend/src/middleware/prisma-sync-hooks.js`**
   - Retiré `date_modification` de la liste des colonnes de `mouvementStock`

## 🎯 Résultat

Après redémarrage:
- ✅ Pas d'erreur "Unknown argument `dateModification`"
- ✅ Mouvements de stock trouvés et synchronisés
- ✅ Données complètes dans Neon
- ✅ Quantités de stock correctes

## 📚 Documentation Associée

- `PRISMA_EXTENSIONS_TRANSACTIONS.md` - Limitation des extensions Prisma
- `FIX_TRANSACTION_TIMEOUT.md` - Correction du timeout
- `CORRECTION_FINALE.txt` - Instructions utilisateur
