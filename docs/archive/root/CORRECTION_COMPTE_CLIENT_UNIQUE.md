# Correction de la contrainte UNIQUE sur compteClient.clientId

## Problème
Erreur lors des ventes à crédit: `ON CONFLICT clause does not match any PRIMARY KEY or UNIQUE constraint`

La table `comptes_clients` n'a pas la contrainte UNIQUE sur la colonne `client_id`.

## Solution

### Étape 1: Créer un script de migration SQL

Créez le fichier `backend/prisma/fix-compte-client-unique.sql`:

```sql
-- Étape 1: Créer une nouvelle table avec la bonne structure
CREATE TABLE comptes_clients_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id INTEGER NOT NULL UNIQUE,
    solde_actuel REAL NOT NULL DEFAULT 0.00,
    limite_credit REAL NOT NULL