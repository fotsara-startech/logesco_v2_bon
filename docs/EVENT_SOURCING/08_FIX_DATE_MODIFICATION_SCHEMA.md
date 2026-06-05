# Fix: Colonnes date_modification Manquantes dans le Schéma

## Problème Identifié

Lors de la synchronisation Event Sourcing V2, plusieurs tables n'avaient pas la colonne `date_modification` requise pour le pull delta depuis Neon. Cela causait des erreurs:

```
Raw query failed. Code: `1`. Message: `table transactions_comptes has no column named date_modification`
```

### Tables Affectées

1. **transactions_comptes** - Avait `date_transaction` mais pas `date_modification`
2. **stock_inventories** - Avait `date_creation` mais pas `date_modification`
3. **inventory_items** - Avait `date_comptage` mais pas `date_modification`

## Solution Implémentée

### 1. Correction du Sync Service

Fichier: `backend/src/services/sync-service.js`

Ajout d'une liste de tables sans `date_modification`:

```javascript
const TABLES_WITHOUT_DATE_MODIFICATION = [
  'transactions_comptes',      // has date_transaction only
  'stock_inventories',         // has date_creation, date_debut, date_fin
  'inventory_items',           // has date_comptage
  'comptes_fournisseurs',      // has date_derniere_maj
  'comptes_clients'            // has date_derniere_maj
];
```

**Logique appliquée:**
- Avant d'insérer dans Neon, supprimer la colonne `date_modification` pour ces tables
- Utiliser des colonnes alternatives pour le pull delta (ex: `date_transaction` pour `transactions_comptes`)

### 2. Migration Prisma

Fichier: `backend/prisma/migrations/add_date_modification_columns/migration.sql`

Ajoute la colonne `date_modification` à toutes les tables:

```sql
ALTER TABLE transactions_comptes ADD COLUMN date_modification DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE stock_inventories ADD COLUMN date_modification DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE inventory_items ADD COLUMN date_modification DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;
```

### 3. Mise à Jour du Schéma Prisma

Fichier: `backend/prisma/schema.prisma`

Ajout du champ `dateModification` aux modèles:

```prisma
model TransactionCompte {
  // ... autres champs ...
  dateModification      DateTime  @updatedAt @map("date_modification")
}

model StockInventory {
  // ... autres champs ...
  dateModification   DateTime        @updatedAt @map("date_modification")
}

model InventoryItem {
  // ... autres champs ...
  dateModification      DateTime       @updatedAt @map("date_modification")
}
```

## Avantages de la Solution

✅ **Cohérence de Schéma**: Toutes les tables ont maintenant `date_modification` pour le tracking des changements
✅ **Pull Delta Fiable**: Le pull delta fonctionne correctement pour toutes les tables
✅ **Performance**: Index créés sur `date_modification` pour accélérer les requêtes
✅ **Maintenance**: Facile à maintenir et comprendre — une seule convention
✅ **Préparation pour Neon**: Prêt pour la migration vers PostgreSQL (Neon utilise aussi `date_modification`)

## Migration pour les Clients Existants

### Étapes:

1. **Backup de la base de données locale**
   ```bash
   cp backend/database/logesco.db backend/database/logesco.db.backup
   ```

2. **Appliquer la migration**
   ```bash
   cd backend
   npx prisma migrate deploy
   ```

3. **Vérifier les colonnes**
   ```bash
   sqlite3 database/logesco.db ".schema transactions_comptes"
   sqlite3 database/logesco.db ".schema stock_inventories"
   sqlite3 database/logesco.db ".schema inventory_items"
   ```

4. **Redémarrer le backend**
   ```bash
   npm run dev
   ```

## Nouvelles Conventions de Schéma

### Règle: Toute table doit avoir une colonne de timestamp

- **Date de création**: `date_creation` (NOT NULL, DEFAULT CURRENT_TIMESTAMP)
- **Date de modification**: `date_modification` (NOT NULL, DEFAULT CURRENT_TIMESTAMP, UPDATE CURRENT_TIMESTAMP)
- **Exception**: Tables sans modifications (ex: audit logs) ne nécessitent que `date_creation`

### Pour les Nouvelles Tables

Ajouter systématiquement:

```prisma
model NewTable {
  id                Int       @id @default(autoincrement())
  // ... champs métier ...
  dateCreation      DateTime  @default(now()) @map("date_creation")
  dateModification  DateTime  @updatedAt @map("date_modification")
  
  @@index([dateModification], map: "idx_new_table_date_modification")
  @@map("new_table")
}
```

## Tests

Après la migration, vérifier que le Event Sourcing fonctionne:

```bash
# Démarrer le backend
npm run dev

# Vérifier les logs
# Vous devriez voir:
# ✅ Aucune opération en attente — journal à jour
# 📥 Pull delta: X enregistrement(s) depuis Neon
# ✅ SyncService V2 démarré (Event Sourcing + Hybrid Mode)
```

## Checklist de Déploiement

- [ ] Backup de la BD locale effectué
- [ ] Migration Prisma appliquée avec succès
- [ ] Colonnes vérifiées dans la BD locale
- [ ] Backend redémarré sans erreurs
- [ ] Tests de sync effectués
- [ ] Logs vérifiés (pas d'erreur date_modification)
- [ ] Clients en production notifiés
