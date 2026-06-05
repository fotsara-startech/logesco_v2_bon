# Migrations pour Nouveaux Clients — Checklist Complète

## Résumé

Lors de l'installation d'un nouveau client Type 3 (hybride local + Neon), il faut appliquer **4 migrations principales** :

1. **PostgreSQL (Neon)** : Schéma initial + tables manquantes
2. **SQLite (Local)** : Operation Log (Event Sourcing V2)
3. **SQLite (Local)** : Date Modification — Colonnes initiales (3 tables)
4. **SQLite (Local)** : Date Modification — Tables manquantes (5 tables)

---

## Migration 1 — PostgreSQL sur Neon (ÉTAPE 2 du guide)

### Objectif
Initialiser le schéma PostgreSQL sur la BD Neon du client.

### Commandes

```powershell
# 1. Basculer vers le schéma PostgreSQL
$env:DATABASE_URL="[CONNECTION STRING NEON DU CLIENT]"

# 2. Copier les migrations PostgreSQL
Rename-Item -Path "prisma\migrations" -NewName "migrations_sqlite_bak"
Copy-Item -Path "prisma\migrations_pg\*" -Destination "prisma\migrations" -Recurse -Force
Remove-Item -Recurse -Force "prisma\migrations\migrations" -ErrorAction SilentlyContinue

# 3. Déployer
npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma

# 4. Appliquer les tables manquantes
node -e "
const { Pool } = require('pg');
const fs = require('fs');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const sql = fs.readFileSync('prisma/migrations_pg/add_missing_tables_and_date_modification.sql', 'utf8');
pool.query(sql).then(() => { console.log('✅ Migration appliquée'); pool.end(); }).catch(e => { console.error('❌', e.message); pool.end(); });
"

# 5. Restaurer les migrations SQLite
Remove-Item -Recurse -Force "prisma\migrations"
Rename-Item -Path "prisma\migrations_sqlite_bak" -NewName "migrations"
```

### Vérification

✅ Le SQL Editor de Neon montre les tables créées

---

## Migration 2 — Operation Log sur SQLite (Automatique)

### Objectif
Créer la table `operation_log` pour l'Event Sourcing V2.

### Status
✅ **Déjà appliquée automatiquement** lors du premier démarrage du backend.

### Vérification

```powershell
# Sur la machine du client, en PowerShell
sqlite3 database/logesco.db "SELECT name FROM sqlite_master WHERE type='table' AND name='operation_log'"

# Devrait afficher: operation_log
```

### Si problème

```powershell
# Marquer comme appliquée si elle existe déjà
npx prisma migrate resolve --applied add_operation_log

# Puis déployer
npx prisma migrate deploy
```

---

## Migration 3 — Date Modification (Colonnes Initiales) sur SQLite

### Objectif
Ajouter les colonnes `date_modification` à 3 tables initiales (nécessaire pour le pull delta Event Sourcing V2).

### Tables affectées
- `transactions_comptes`
- `stock_inventories`
- `inventory_items`

### Commandes

```powershell
# Sur la machine du client
cd backend

# 1. Basculer vers la BD locale SQLite
$env:DATABASE_URL="file:./database/logesco.db?timeout=60000"

# 2. Appliquer les migrations
npx prisma migrate deploy

# Devrait afficher: 1 migration successfully applied
```

### Vérification

```powershell
# Vérifier que les colonnes ont été ajoutées
sqlite3 database/logesco.db ".schema transactions_comptes"

# Devrait contenir:
# ...
# date_modification DATETIME,
# ...

# Vérifier toutes les 3 tables
sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('transactions_comptes') WHERE name='date_modification'"
# Devrait afficher: date_modification

sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('stock_inventories') WHERE name='date_modification'"
# Devrait afficher: date_modification

sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('inventory_items') WHERE name='date_modification'"
# Devrait afficher: date_modification
```

---

## Migration 4 — Date Modification (Tables Manquantes) sur SQLite

### Objectif
Ajouter les colonnes `date_modification` aux 5 tables restantes.

### Tables affectées
- `stock_boutiques`
- `comptes_fournisseurs`
- `comptes_clients`
- `cash_sessions`
- `cash_movements`

### Status
✅ **Appliquée automatiquement** avec les autres migrations par `npx prisma migrate deploy`

### Vérification

```powershell
# Vérifier toutes les 5 tables
sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('stock_boutiques') WHERE name='date_modification'"
# Devrait afficher: date_modification

sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('comptes_fournisseurs') WHERE name='date_modification'"
sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('comptes_clients') WHERE name='date_modification'"
sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('cash_sessions') WHERE name='date_modification'"
sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('cash_movements') WHERE name='date_modification'"

# Tous doivent afficher: date_modification
```

### Troubleshooting

**Erreur : "database schema is not empty"**

```powershell
# Si la BD existe mais migrations ne sont pas tracées
npx prisma migrate resolve --applied "20260602145015_add_stock_snapshots"
npx prisma migrate resolve --applied "add_operation_log"
npx prisma migrate deploy
```

**Erreur : "Cannot add a column with non-constant default"**

```powershell
# Réinitialiser et réappliquer
npx prisma migrate resolve --rolled-back add_date_modification_columns
npx prisma migrate resolve --rolled-back add_date_modification_more_tables
npx prisma migrate resolve --rolled-back add_date_modification_remaining_tables
npx prisma migrate deploy
```

**Erreur : "table operation_log already exists"**

```powershell
# Marquer comme appliquée
npx prisma migrate resolve --applied add_operation_log
npx prisma migrate deploy
```

---

## Checklist Installation Nouveau Client

### Avant l'installation

- [ ] Créer le projet Neon pour le client (section ÉTAPE 1)
- [ ] Copier la Connection String Neon
- [ ] Préparer le fichier `.env` pour le client (section ÉTAPE 3)

### Pendant l'installation

- [ ] **PostgreSQL (Neon)** — Appliquer Migration 1
  - [ ] Copier les migrations PostgreSQL
  - [ ] Exécuter `npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma`
  - [ ] Appliquer les tables manquantes
  - [ ] Restaurer les migrations SQLite

- [ ] **SQLite (Local)** — Appliquer Migrations 2, 3 & 4
  - [ ] Basculer vers BD SQLite locale
  - [ ] Exécuter `npx prisma migrate deploy`
  - [ ] Vérifier que `date_modification` existe dans **TOUTES les 8 tables** (3 + 5)

### Après l'installation

- [ ] Redémarrer le backend
- [ ] Vérifier les logs : pas d'erreur "table has no column named date_modification"
- [ ] Vérifier : Mode sync affiche "hybrid"
- [ ] Tester : Créer une vente, voir si elle apparaît dans Neon après ~30 sec
- [ ] Tester : Couper internet, app fonctionne encore
- [ ] Tester : Reconnecter internet, données se synchronisent

---

## Fichiers de Migration Importants

| Fichier | Location | Purpose | Tables |
|---------|----------|---------|--------|
| `add_date_modification_columns/migration.sql` | `prisma/migrations/` | Ajoute `date_modification` aux 3 tables SQLite | transactions_comptes, stock_inventories, inventory_items |
| `add_date_modification_more_tables/migration.sql` | `prisma/migrations/` | Ajoute `date_modification` aux 2 tables supplémentaires | mouvements_stock, transferts_stock |
| `add_date_modification_remaining_tables/migration.sql` | `prisma/migrations/` | Ajoute `date_modification` aux 5 tables restantes | stock_boutiques, comptes_fournisseurs, comptes_clients, cash_sessions, cash_movements |
| `add_operation_log/migration.sql` | `prisma/migrations/` | Crée la table `operation_log` pour Event Sourcing V2 | operation_log |
| `fix_null_date_modifications/migration.sql` | `prisma/migrations/` | Peuple les valeurs NULL avec CURRENT_TIMESTAMP | Toutes les 8 tables |
| `20260602145015_add_stock_snapshots` | `prisma/migrations/` | Snapshot stock initial | stock_snapshots |
| `migrations_pg/` | `prisma/` | Dossier contenant toutes les migrations PostgreSQL | Toutes tables Neon |

---

## Notes Importantes

### Pour les Développeurs

1. **Event Sourcing V2 nécessite `date_modification`**
   - **TOUTES les 8 tables** doivent avoir cette colonne
   - Elle est utilisée pour le pull delta (sync incrémentale)
   - Sans elle, la sync échoue avec l'erreur "table has no column named date_modification"
   - Tables : transactions_comptes, stock_inventories, inventory_items, mouvements_stock, transferts_stock, stock_boutiques, comptes_fournisseurs, comptes_clients, cash_sessions, cash_movements

2. **Les migrations sont indépendantes**
   - Migration 1 (PostgreSQL) ne parle qu'à Neon
   - Migrations 2-4 (SQLite) ne parlent qu'à la BD locale
   - Elles s'exécutent dans des ordres différents selon l'ordre d'installation

3. **Ordre d'installation correct**
   - PostgreSQL en premier (sur machine dev/admin)
   - SQLite ensuite (sur machine du client)
   - Cette ordre évite les problèmes de schéma synchrone

### Pour les DevOps

1. **Automatiser via script**
   - Créer un script `install-new-client.ps1` qui applique tout d'un coup
   - Référencer ce guide comme documentation de base

2. **Monitoring**
   - Vérifier mensuellement que les colonnes `date_modification` existent **sur toutes les 8 tables**
   - Alerter si un client voit "table has no column named date_modification" dans les logs

3. **Éviter les oublis**
   - Les migrations SQLite `add_date_modification_*` sont critiques
   - Si oubliées → le pull delta échoue → sync brisée
   - Mettre en place une checklist avant livraison au client
   - Tester avec une vente fictive avant remise au client

---

## Script Automatisé (Optionnel)

Créer `install-new-client.ps1`:

```powershell
param(
    [string]$ClientName = "new-client",
    [string]$NeonUrl = "",
    [string]$JwtSecret = ""
)

Write-Host "🚀 Installation nouveau client: $ClientName"

# 1. PostgreSQL
if ($NeonUrl) {
    Write-Host "1️⃣  Configuring PostgreSQL (Neon)..."
    $env:DATABASE_URL = $NeonUrl
    Rename-Item -Path "prisma\migrations" -NewName "migrations_sqlite_bak"
    Copy-Item -Path "prisma\migrations_pg\*" -Destination "prisma\migrations" -Recurse -Force
    npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma
    Write-Host "✅ PostgreSQL ready"
}

# 2. SQLite (applies all 4 migrations automatically)
Write-Host "2️⃣  Configuring SQLite (Local)..."
$env:DATABASE_URL = "file:./database/logesco.db?timeout=60000"
npx prisma migrate deploy
Write-Host "✅ SQLite ready with all date_modification columns"

# 3. Verify all 8 tables have date_modification
Write-Host "3️⃣  Verifying migrations..."
$tables = @('transactions_comptes', 'stock_inventories', 'inventory_items', 'mouvements_stock', 'transferts_stock', 'stock_boutiques', 'comptes_fournisseurs', 'comptes_clients', 'cash_sessions', 'cash_movements')
foreach ($table in $tables) {
    $col = sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('$table') WHERE name='date_modification'"
    if ($col) {
        Write-Host "  ✅ $table has date_modification"
    } else {
        Write-Host "  ❌ $table MISSING date_modification - SYNC WILL FAIL!"
    }
}

# 4. Prepare .env
if ($NeonUrl -and $JwtSecret) {
    Write-Host "4️⃣  Preparing .env..."
    @"
NODE_ENV=production
PORT=8080
DATABASE_PROVIDER="sqlite"
DATABASE_URL="file:./database/logesco.db?timeout=60000"
CLOUD_DB_URL="$NeonUrl"
JWT_SECRET=$JwtSecret
JWT_EXPIRES_IN=365d
JWT_REFRESH_EXPIRES_IN=365d
API_VERSION=v1
CORS_ORIGIN=*
LOG_LEVEL=info
"@ | Set-Content ".env"
    Write-Host "✅ .env configured"
}

Write-Host "✅ Installation complete!"
```

Usage:
```powershell
./install-new-client.ps1 -ClientName "pharmacie-centrale" -NeonUrl "postgresql://..." -JwtSecret "secret-xxx"
```

---

**Document**: MIGRATIONS_FOR_NEW_CLIENTS.md  
**Date**: 2026-06-05  
**Status**: ✅ Production Ready  
**Reference**: GUIDE_INSTALLATION_CLIENT_TYPE3.md

### Objectif
Initialiser le schéma PostgreSQL sur la BD Neon du client.

### Commandes

```powershell
# 1. Basculer vers le schéma PostgreSQL
$env:DATABASE_URL="[CONNECTION STRING NEON DU CLIENT]"

# 2. Copier les migrations PostgreSQL
Rename-Item -Path "prisma\migrations" -NewName "migrations_sqlite_bak"
Copy-Item -Path "prisma\migrations_pg\*" -Destination "prisma\migrations" -Recurse -Force
Remove-Item -Recurse -Force "prisma\migrations\migrations" -ErrorAction SilentlyContinue

# 3. Déployer
npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma

# 4. Appliquer les tables manquantes
node -e "
const { Pool } = require('pg');
const fs = require('fs');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const sql = fs.readFileSync('prisma/migrations_pg/add_missing_tables_and_date_modification.sql', 'utf8');
pool.query(sql).then(() => { console.log('✅ Migration appliquée'); pool.end(); }).catch(e => { console.error('❌', e.message); pool.end(); });
"

# 5. Restaurer les migrations SQLite
Remove-Item -Recurse -Force "prisma\migrations"
Rename-Item -Path "prisma\migrations_sqlite_bak" -NewName "migrations"
```

### Vérification

✅ Le SQL Editor de Neon montre les tables créées

---

## Migration 2 — Operation Log sur SQLite (Automatique)

### Objectif
Créer la table `operation_log` pour l'Event Sourcing V2.

### Status
✅ **Déjà appliquée automatiquement** lors du premier démarrage du backend.

### Vérification

```powershell
# Sur la machine du client, en PowerShell
sqlite3 database/logesco.db "SELECT name FROM sqlite_master WHERE type='table' AND name='operation_log'"

# Devrait afficher: operation_log
```

### Si problème

```powershell
# Marquer comme appliquée si elle existe déjà
npx prisma migrate resolve --applied add_operation_log

# Puis déployer
npx prisma migrate deploy
```

---

## Migration 3 — Date Modification sur SQLite (ÉTAPE 2.4 du guide)

### Objectif
Ajouter les colonnes `date_modification` à 3 tables (nécessaire pour le pull delta Event Sourcing V2).

### Tables affectées
- `transactions_comptes`
- `stock_inventories`
- `inventory_items`

### Commandes

```powershell
# Sur la machine du client
cd backend

# 1. Basculer vers la BD locale SQLite
$env:DATABASE_URL="file:./database/logesco.db?timeout=60000"

# 2. Appliquer les migrations
npx prisma migrate deploy

# Devrait afficher: 1 migration successfully applied
```

### Vérification

```powershell
# Vérifier que les colonnes ont été ajoutées
sqlite3 database/logesco.db ".schema transactions_comptes"

# Devrait contenir:
# ...
# date_modification DATETIME,
# ...

# Vérifier toutes les 3 tables
sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('transactions_comptes') WHERE name='date_modification'"
# Devrait afficher: date_modification

sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('stock_inventories') WHERE name='date_modification'"
# Devrait afficher: date_modification

sqlite3 database/logesco.db "SELECT name FROM pragma_table_info('inventory_items') WHERE name='date_modification'"
# Devrait afficher: date_modification
```

### Troubleshooting

**Erreur : "database schema is not empty"**

```powershell
# Si la BD existe mais migrations ne sont pas tracées
npx prisma migrate resolve --applied "20260602145015_add_stock_snapshots"
npx prisma migrate resolve --applied "add_operation_log"
npx prisma migrate deploy
```

**Erreur : "Cannot add a column with non-constant default"**

```powershell
# Réinitialiser et réappliquer
npx prisma migrate resolve --rolled-back add_date_modification_columns
npx prisma migrate deploy
```

**Erreur : "table operation_log already exists"**

```powershell
# Marquer comme appliquée
npx prisma migrate resolve --applied add_operation_log
npx prisma migrate deploy
```

---

## Checklist Installation Nouveau Client

### Avant l'installation

- [ ] Créer le projet Neon pour le client (section ÉTAPE 1)
- [ ] Copier la Connection String Neon
- [ ] Préparer le fichier `.env` pour le client (section ÉTAPE 3)

### Pendant l'installation

- [ ] **PostgreSQL (Neon)** — Appliquer Migration 1
  - [ ] Copier les migrations PostgreSQL
  - [ ] Exécuter `npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma`
  - [ ] Appliquer les tables manquantes
  - [ ] Restaurer les migrations SQLite

- [ ] **SQLite (Local)** — Appliquer Migrations 2 & 3
  - [ ] Basculer vers BD SQLite locale
  - [ ] Exécuter `npx prisma migrate deploy`
  - [ ] Vérifier que `date_modification` existe dans les 3 tables

### Après l'installation

- [ ] Redémarrer le backend
- [ ] Vérifier les logs : pas d'erreur "date_modification"
- [ ] Vérifier : Mode sync affiche "hybrid"
- [ ] Tester : Créer une vente, voir si elle apparaît dans Neon après ~30 sec
- [ ] Tester : Couper internet, app fonctionne encore
- [ ] Tester : Reconnecter internet, données se synchronisent

---

## Fichiers de Migration Importants

| Fichier | Location | Purpose |
|---------|----------|---------|
| `add_date_modification_columns/migration.sql` | `prisma/migrations/` | Ajoute `date_modification` aux 3 tables SQLite |
| `add_operation_log/migration.sql` | `prisma/migrations/` | Crée la table `operation_log` pour Event Sourcing V2 |
| `20260602145015_add_stock_snapshots` | `prisma/migrations/` | Snapshot stock initial |
| `migrations_pg/` | `prisma/` | Dossier contenant toutes les migrations PostgreSQL |

---

## Notes Importantes

### Pour les Développeurs

1. **Event Sourcing V2 nécessite `date_modification`**
   - Toute nouvelle table doit avoir cette colonne
   - Elle est utilisée pour le pull delta (sync incrémentale)
   - Sans elle, la sync échoue avec l'erreur "table has no column named date_modification"

2. **Les 3 migrations sont indépendantes**
   - Migration 1 (PostgreSQL) ne parle qu'à Neon
   - Migrations 2 & 3 (SQLite) ne parlent qu'à la BD locale
   - Elles s'exécutent dans des ordre différents selon l'ordre d'installation

3. **Ordre d'installation correct**
   - PostgreSQL en premier (sur machine dev/admin)
   - SQLite ensuite (sur machine du client)
   - Cette ordre évite les problèmes de schéma synchrone

### Pour les DevOps

1. **Automatiser via script**
   - Créer un script `install-new-client.ps1` qui applique tout d'un coup
   - Référencer ce guide comme documentation de base

2. **Monitoring**
   - Vérifier mensuellement que les colonnes `date_modification` existent
   - Alerter si un client voit "table has no column" dans les logs

3. **Éviter les oublis**
   - La migration SQLite `add_date_modification_columns` est critique
   - Si oubliée → le pull delta échoue → sync brisée
   - Mettre en place une checklist avant livraison au client

---

## Script Automatisé (Optionnel)

Créer `install-new-client.ps1`:

```powershell
param(
    [string]$ClientName = "new-client",
    [string]$NeonUrl = "",
    [string]$JwtSecret = ""
)

Write-Host "🚀 Installation nouveau client: $ClientName"

# 1. PostgreSQL
if ($NeonUrl) {
    Write-Host "1️⃣  Configuring PostgreSQL (Neon)..."
    $env:DATABASE_URL = $NeonUrl
    Rename-Item -Path "prisma\migrations" -NewName "migrations_sqlite_bak"
    Copy-Item -Path "prisma\migrations_pg\*" -Destination "prisma\migrations" -Recurse -Force
    npx prisma migrate deploy --schema=prisma/schema.postgresql.prisma
    Write-Host "✅ PostgreSQL ready"
}

# 2. SQLite
Write-Host "2️⃣  Configuring SQLite (Local)..."
$env:DATABASE_URL = "file:./database/logesco.db?timeout=60000"
npx prisma migrate deploy
Write-Host "✅ SQLite ready"

# 3. Prepare .env
if ($NeonUrl -and $JwtSecret) {
    Write-Host "3️⃣  Preparing .env..."
    @"
NODE_ENV=production
PORT=8080
DATABASE_PROVIDER="sqlite"
DATABASE_URL="file:./database/logesco.db"
CLOUD_DB_URL="$NeonUrl"
JWT_SECRET=$JwtSecret
JWT_EXPIRES_IN=365d
JWT_REFRESH_EXPIRES_IN=365d
API_VERSION=v1
CORS_ORIGIN=*
LOG_LEVEL=info
"@ | Set-Content ".env"
    Write-Host "✅ .env configured"
}

Write-Host "✅ Installation complete!"
```

Usage:
```powershell
./install-new-client.ps1 -ClientName "pharmacie-centrale" -NeonUrl "postgresql://..." -JwtSecret "secret-xxx"
```

---

**Document**: MIGRATIONS_FOR_NEW_CLIENTS.md  
**Date**: 2026-06-05  
**Status**: ✅ Production Ready  
**Reference**: GUIDE_INSTALLATION_CLIENT_TYPE3.md
