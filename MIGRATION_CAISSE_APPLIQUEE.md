# Migration Base de Données - Gestion de Caisse

## Problème Rencontré

Lors de la clôture d'une session de caisse, l'erreur suivante se produisait:

```
Unknown argument `soldeAttendu`. Available options are marked with ?.
```

**Cause**: Les colonnes `solde_attendu` et `ecart` n'existaient pas encore dans la table `cash_sessions`.

## Solution Appliquée

### 1. Correction de la Migration SQL

Le fichier de migration initial utilisait la syntaxe MySQL (`AFTER`), incompatible avec SQLite.

**Fichier**: `backend/prisma/migrations/add_cash_session_fields/migration.sql`

**Avant** (MySQL):
```sql
ALTER TABLE `cash_sessions` ADD COLUMN `solde_attendu` DOUBLE NULL AFTER `solde_fermeture`;
ALTER TABLE `cash_sessions` ADD COLUMN `ecart` DOUBLE NULL AFTER `solde_attendu`;
```

**Après** (SQLite):
```sql
ALTER TABLE `cash_sessions` ADD COLUMN `solde_attendu` REAL;
ALTER TABLE `cash_sessions` ADD COLUMN `ecart` REAL;
```

### 2. Application de la Migration

Création d'un script Node.js pour ajouter les colonnes:

**Fichier**: `backend/add-cash-session-columns.js`

Le script:
- Vérifie si les colonnes existent déjà
- Ajoute `solde_attendu` si nécessaire
- Ajoute `ecart` si nécessaire
- Affiche les colonnes avant et après

**Exécution**:
```bash
cd backend
node add-cash-session-columns.js
```

**Résultat**:
```
✅ Colonne solde_attendu ajoutée
✅ Colonne ecart ajoutée
```

### 3. Régénération du Client Prisma

Pour que les changements soient pris en compte, il faut:

1. **Arrêter le backend** (pour libérer le verrou sur les fichiers Prisma)
2. **Régénérer le client**:
   ```bash
   cd backend
   npx prisma generate
   ```
3. **Redémarrer le backend**

**Script automatique créé**: `backend/restart-backend-with-migration.bat`

## Colonnes Ajoutées

| Colonne | Type | Description |
|---------|------|-------------|
| `solde_attendu` | REAL | Solde théorique calculé (ouverture + ventes - dépenses) |
| `ecart` | REAL | Différence entre solde déclaré et solde attendu |

## Structure Finale de la Table

```
cash_sessions:
  - id
  - caisse_id
  - utilisateur_id
  - solde_ouverture
  - solde_fermeture
  - solde_attendu      ← NOUVEAU
  - ecart              ← NOUVEAU
  - date_ouverture
  - date_fermeture
  - is_active
  - metadata
```

## Prochaines Étapes

1. ✅ Migration appliquée
2. ⏳ Redémarrer le backend avec `restart-backend-with-migration.bat`
3. ⏳ Tester la clôture d'une session de caisse
4. ⏳ Vérifier le calcul automatique des écarts

## Commandes Utiles

### Vérifier les colonnes de la table
```bash
cd backend
node -e "const {PrismaClient} = require('@prisma/client'); const p = new PrismaClient(); p.\$queryRaw\`PRAGMA table_info(cash_sessions)\`.then(r => console.log(r.map(c => c.name))).finally(() => p.\$disconnect())"
```

### Appliquer la migration manuellement
```bash
cd backend
node add-cash-session-columns.js
```

### Régénérer le client Prisma
```bash
cd backend
npx prisma generate
```
