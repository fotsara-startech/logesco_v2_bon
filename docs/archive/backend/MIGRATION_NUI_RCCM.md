# Guide d'application de la migration NUI/RCCM

## Migration ajoutée
**Nom** : `20260717125521_add_nui_rccm_to_clients`

Cette migration ajoute les champs NUI et RCCM aux clients pour les entreprises.

## Étapes d'application

### 1. Appliquer la migration en production

```bash
cd backend
npx prisma migrate deploy
```

### 2. Vérifier que la migration est appliquée

```bash
npx prisma migrate status
```

### 3. Régénérer le client Prisma (déjà fait)

```bash
npx prisma generate
```

### 4. Redémarrer le serveur backend

```bash
# Si vous utilisez PM2
pm2 restart logesco-api

# Ou si vous utilisez node directement
# Arrêter le serveur en cours et relancer
npm start
```

## Rollback (si nécessaire)

Si vous devez annuler cette migration :

```sql
-- Supprimer les colonnes
ALTER TABLE clients DROP COLUMN IF EXISTS nui;
ALTER TABLE clients DROP COLUMN IF EXISTS rccm;

-- Supprimer les index
DROP INDEX IF EXISTS idx_clients_nui;
DROP INDEX IF EXISTS idx_clients_rccm;
```

## Vérification

Pour vérifier que les colonnes ont été ajoutées correctement :

```sql
-- Vérifier la structure de la table
\d clients;

-- Ou avec une requête SQL standard
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'clients' 
  AND column_name IN ('nui', 'rccm');
```

## Notes

- Les colonnes sont nullables (optionnelles)
- Des index ont été créés pour optimiser les recherches futures
- Aucune donnée existante n'est modifiée
- La migration est compatible avec les anciennes données

## Test

Après application de la migration, testez :

1. Créer un nouveau client avec NUI et RCCM
2. Modifier un client existant en ajoutant NUI et RCCM
3. Générer un reçu pour un client avec NUI/RCCM
4. Vérifier que NUI et RCCM apparaissent sur le reçu
