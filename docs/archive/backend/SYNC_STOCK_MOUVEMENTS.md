# Synchronisation Automatique des Stocks et Mouvements

## Problème Résolu

Les tables `stock_boutiques` et `mouvements_stock` n'étaient pas synchronisées vers Neon car elles sont modifiées **indirectement** lors de ventes ou mouvements de stock, et non via des routes API dédiées.

### Symptômes
- ✅ Ventes créées en local
- ✅ Mouvements de stock créés en local
- ✅ Quantités mises à jour en local
- ❌ Aucune synchronisation vers Neon
- ❌ Données manquantes sur Neon

## Solution Implémentée

### Hooks Prisma Automatiques

Un système de hooks Prisma a été mis en place pour intercepter **toutes** les opérations d'écriture sur les tables critiques et les synchroniser automatiquement vers Neon.

### Tables Synchronisées Automatiquement

1. **`mouvements_stock`** (mouvementStock)
   - Créés lors de ventes
   - Créés lors de mouvements manuels
   - Créés lors de réceptions de commandes
   - Créés lors d'inventaires

2. **`stock_boutiques`** (stockBoutique)
   - Mis à jour lors de ventes
   - Mis à jour lors de mouvements de stock
   - Mis à jour lors de transferts entre boutiques
   - Mis à jour lors de réceptions de commandes

3. **`stock`** (stock global)
   - Mis à jour lors d'opérations sur le stock global

## Architecture

### Fichiers Modifiés

1. **`src/middleware/prisma-sync-hooks.js`** (NOUVEAU)
   - Définit les hooks Prisma
   - Intercepte les opérations create/update/delete
   - Prépare les données pour la synchronisation
   - Envoie vers le service de sync

2. **`src/config/prisma-client.js`**
   - Ajout de `setupPrismaSyncHooks()` lors de la création de l'instance

3. **`src/config/database.js`**
   - Ajout de `setupPrismaSyncHooks()` lors de l'initialisation

4. **`src/middleware/sync-middleware.js`**
   - Ajout des configurations pour stock_movements et stock_boutiques (pour référence)

### Flux de Synchronisation

```
┌─────────────────────────────────────────────────────────────┐
│  Opération Prisma (create/update/delete)                    │
│  Ex: prisma.mouvementStock.create(...)                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Hook Prisma Intercepte                                     │
│  - Vérifie si la table est dans SYNC_TABLES                 │
│  - Récupère les données complètes depuis la BD              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Préparation des Données                                    │
│  - Filtre les colonnes autorisées                           │
│  - Convertit camelCase → snake_case                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  syncService.enqueue()                                      │
│  - Ajoute à la queue de synchronisation                     │
│  - Push vers Neon lors du prochain cycle                    │
└─────────────────────────────────────────────────────────────┘
```

## Opérations Interceptées

### CREATE
- `prisma.mouvementStock.create()`
- `prisma.mouvementStock.createMany()`
- `prisma.stockBoutique.create()`

### UPDATE
- `prisma.stockBoutique.update()`
- `prisma.stock.update()`

### UPSERT
- `prisma.stockBoutique.upsert()`

### DELETE
- `prisma.mouvementStock.delete()`
- `prisma.stockBoutique.delete()`

## Configuration

### Variables d'Environnement

```env
# Activer la synchronisation
CLOUD_DB_URL="postgresql://..."

# Debug (optionnel)
DEBUG_SYNC=true
```

### Ajouter une Nouvelle Table

Pour ajouter une nouvelle table à la synchronisation automatique:

1. Modifier `src/middleware/prisma-sync-hooks.js`:

```javascript
const SYNC_TABLES = {
  // ... tables existantes
  nouvelleTable: {
    table: 'nouvelle_table',
    columns: [
      'id', 'colonne1', 'colonne2', 'date_modification'
    ]
  }
};
```

2. Redémarrer le serveur

## Vérification

### Logs de Debug

Avec `DEBUG_SYNC=true`, vous verrez:

```
✅ Hooks Prisma de synchronisation activés pour: mouvementStock, stockBoutique, stock
🔄 [Prisma Hook] mouvements_stock (INSERT): { id: 123, produit_id: 45, ... }
📤 Push 1 opération(s) vers Neon...
```

### Vérifier la Synchronisation

1. **Effectuer une vente**
2. **Vérifier les logs** pour voir:
   - Création du mouvement de stock
   - Mise à jour du stock boutique
   - Push vers Neon

3. **Vérifier sur Neon**:
```sql
SELECT * FROM mouvements_stock ORDER BY id DESC LIMIT 10;
SELECT * FROM stock_boutiques WHERE produit_id = X;
```

## Performance

### Impact Minimal

- Les hooks s'exécutent **après** l'opération principale
- Les erreurs de sync ne bloquent **pas** l'opération
- La synchronisation est **asynchrone**
- Pas d'impact sur les temps de réponse

### Optimisations

- Utilisation de `findUnique()` pour récupérer les données (rapide)
- Filtrage des colonnes pour réduire la taille des données
- Gestion d'erreurs pour éviter les blocages

## Dépannage

### Les données ne se synchronisent pas

1. Vérifier que `CLOUD_DB_URL` est défini
2. Vérifier les logs pour voir si les hooks sont activés:
   ```
   ✅ Hooks Prisma de synchronisation activés pour: ...
   ```
3. Activer `DEBUG_SYNC=true` pour voir les détails

### Erreurs dans les logs

```
❌ Erreur sync hook mouvementStock: ...
```

- L'opération principale a réussi (données en local)
- Seule la synchronisation a échoué
- Vérifier la connexion Neon
- Vérifier que les colonnes existent sur Neon

### Données manquantes sur Neon

1. Vérifier que les colonnes `date_modification` existent:
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name IN ('mouvements_stock', 'stock_boutiques')
AND column_name = 'date_modification';
```

2. Si manquantes, exécuter:
```bash
node setup-neon.js
```

## Limitations

### Opérations Non Interceptées

- `$executeRaw` et `$queryRaw` ne sont **pas** interceptés
- Modifications directes en SQL ne sont **pas** synchronisées
- Utiliser toujours les méthodes Prisma pour garantir la sync

### Transactions

- Les hooks fonctionnent **dans** les transactions
- La synchronisation se fait **après** le commit
- En cas de rollback, rien n'est synchronisé (comportement correct)

## Tests

### Test Manuel

1. Créer une vente depuis l'application
2. Vérifier les logs:
```
🔄 [Prisma Hook] mouvements_stock (INSERT): ...
🔄 [Prisma Hook] stock_boutiques (UPDATE): ...
📤 Push 2 opération(s) vers Neon...
```

3. Vérifier sur Neon que les données sont présentes

### Test Automatique

```javascript
// test-stock-sync.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function testStockSync() {
  // Créer un mouvement de stock
  const mouvement = await prisma.mouvementStock.create({
    data: {
      produitId: 1,
      boutiqueId: 1,
      typeMouvement: 'entree',
      changementQuantite: 10,
      dateMouvement: new Date()
    }
  });
  
  console.log('✅ Mouvement créé:', mouvement.id);
  console.log('🔍 Vérifiez les logs pour voir la synchronisation');
}

testStockSync();
```

## Maintenance

### Ajouter des Colonnes

Si vous ajoutez une colonne à une table synchronisée:

1. Ajouter dans le schéma Prisma
2. Créer la migration
3. Mettre à jour `SYNC_TABLES` dans `prisma-sync-hooks.js`
4. Redémarrer le serveur

### Désactiver Temporairement

Pour désactiver la synchronisation automatique:

```env
# Commenter ou supprimer CLOUD_DB_URL
# CLOUD_DB_URL="postgresql://..."
```

Les hooks ne seront pas activés au démarrage.

## Avantages

✅ **Automatique**: Aucune modification de code nécessaire dans les routes  
✅ **Transparent**: Fonctionne avec le code existant  
✅ **Fiable**: Intercepte toutes les opérations Prisma  
✅ **Performant**: Impact minimal sur les performances  
✅ **Robuste**: Les erreurs de sync ne bloquent pas les opérations  
✅ **Extensible**: Facile d'ajouter de nouvelles tables  

---

**Version**: 1.0  
**Date**: 2026-04-29  
**Auteur**: Équipe LOGESCO
