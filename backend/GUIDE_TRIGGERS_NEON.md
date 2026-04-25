# Guide : Configuration des Triggers PostgreSQL pour la Synchronisation

## Problème

Quand vous modifiez directement des données dans Neon (via l'interface web ou un client SQL), le champ `date_modification` n'est pas mis à jour automatiquement. Cela empêche la synchronisation de détecter les changements.

## Solution : Triggers PostgreSQL

Les triggers PostgreSQL mettent automatiquement à jour `date_modification` lors de toute modification, même en dehors de Prisma.

## Étapes d'installation

### 1. Se connecter à Neon

Connectez-vous à votre base de données Neon via :
- L'interface web Neon (SQL Editor)
- Un client PostgreSQL (psql, DBeaver, pgAdmin, etc.)

### 2. Exécuter le script SQL

Copiez et exécutez le contenu du fichier `backend/prisma/migrations_pg/add_update_triggers.sql` dans votre base Neon.

Le script :
1. Crée une fonction `update_date_modification()` qui met à jour le timestamp
2. Applique des triggers sur toutes les tables synchronisées

### 3. Vérifier l'installation

```sql
-- Vérifier que la fonction existe
SELECT proname FROM pg_proc WHERE proname = 'update_date_modification';

-- Vérifier les triggers installés
SELECT tgname, tgrelid::regclass 
FROM pg_trigger 
WHERE tgname LIKE '%date_modification%';
```

### 4. Tester

```sql
-- Modifier un client
UPDATE clients SET nom = 'Test Modifié' WHERE id = 1;

-- Vérifier que date_modification a été mis à jour
SELECT id, nom, date_modification FROM clients WHERE id = 1;
```

## Tables concernées

Les triggers sont appliqués sur :
- `clients`
- `utilisateurs`
- `boutiques`
- `categories`
- `produits`
- `fournisseurs`
- `stock`
- `stock_boutiques`
- `cash_registers`
- `cash_sessions`
- `movement_categories`
- `ventes`
- `mouvements_stock`

## Synchronisation

Une fois les triggers installés :
1. Toute modification dans Neon met à jour `date_modification`
2. Le backend local détecte le changement lors du prochain cycle (30 secondes max)
3. Les données sont synchronisées automatiquement vers la base locale

## Actualisation manuelle

Dans l'application Flutter, vous pouvez aussi :
- **Tirer vers le bas** (pull-to-refresh) dans la liste des clients
- **Cliquer sur le bouton d'actualisation** (🔄) dans l'AppBar

## Dépannage

### Les données ne se synchronisent toujours pas

1. Vérifiez que le backend est en cours d'exécution
2. Vérifiez les logs du backend pour voir les cycles de sync
3. Vérifiez que `CLOUD_DB_URL` est configuré dans `.env`
4. Vérifiez que la connexion à Neon est active (logs : "☁️ Connexion Neon établie")

### Voir les logs de synchronisation

Dans les logs du backend, cherchez :
```
📥 Pull X enregistrement(s) depuis Neon
```

Si vous ne voyez pas ce message, la synchronisation ne détecte aucun changement.

### Forcer une synchronisation immédiate

Créez ou modifiez un enregistrement via l'API (pas directement dans Neon) pour déclencher un cycle de sync immédiat.
