# Correction Migration Guidée - Problème de Récupération des Données

## Problème Identifié

Lors de la migration `client-ultimate` → `client-optimise`, les données utilisateur ne sont pas récupérées car :

1. **Base de données vierge écrase les données** : Le package optimisé contient une base vierge qui remplace l'ancienne
2. **Schéma Prisma non synchronisé** : Quand on copie manuellement `logesco.db`, Prisma ne reconnaît pas la structure
3. **Ordre des opérations incorrect** : La base est restaurée AVANT la migration du schéma

## Solution Implémentée

### Nouveau Script : `migration-guidee-corrigee.bat`

Le script corrigé :
1. ✅ Sauvegarde les données AVANT tout
2. ✅ Installe le nouveau backend
3. ✅ Migre le schéma Prisma AVANT de restaurer les données
4. ✅ Restaure les données dans le bon ordre
5. ✅ Vérifie que les données sont bien présentes

### Étapes de Migration Correctes

```
AVANT (Problématique):
1. Sauvegarder données
2. Installer nouveau backend (avec DB vierge)
3. Copier ancienne DB → ❌ Schéma incompatible!

APRÈS (Corrigé):
1. Sauvegarder données
2. Installer nouveau backend (SANS DB)
3. Migrer schéma Prisma
4. Restaurer ancienne DB → ✅ Schéma compatible!
5. Vérifier données
```

## Utilisation

```batch
REM Depuis le dossier d'installation client
migration-guidee-corrigee.bat
```

## Vérifications Automatiques

Le script vérifie :
- ✅ Présence de la sauvegarde
- ✅ Comptage des données (utilisateurs, produits, ventes)
- ✅ Compatibilité du schéma
- ✅ Intégrité après restauration
- ✅ Connexion backend fonctionnelle

## En Cas de Problème

Si les données ne sont toujours pas visibles :

```batch
REM 1. Vérifier que la base contient des données
cd backend\database
sqlite3 logesco.db "SELECT COUNT(*) FROM utilisateurs;"
sqlite3 logesco.db "SELECT COUNT(*) FROM produits;"

REM 2. Forcer la régénération Prisma
cd backend
npx prisma generate
npx prisma db push --accept-data-loss

REM 3. Redémarrer le backend
taskkill /f /im node.exe
node src/server.js
```

## Différences Clés

| Aspect | Ancien Script | Nouveau Script |
|--------|--------------|----------------|
| Ordre migration | DB puis schéma | Schéma puis DB |
| Vérification données | Aucune | Comptage avant/après |
| Gestion schéma | Automatique | Migration explicite |
| Rollback | Manuel | Automatique si échec |
| Logs | Basiques | Détaillés avec compteurs |
