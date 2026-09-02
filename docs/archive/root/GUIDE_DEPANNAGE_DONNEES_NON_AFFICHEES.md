## Guide de Dépannage - Données Non Affichées dans l'Application

## 🔴 SYMPTÔME

- La base de données contient des données (vérifié avec sqlite)
- La migration s'est terminée sans erreur
- Mais l'application n'affiche AUCUNE donnée
- Les produits, ventes, utilisateurs n'apparaissent pas

## 🔍 DIAGNOSTIC

C'est un problème de **synchronisation du schéma Prisma**. Les données sont dans la BD mais Prisma ne peut pas les lire correctement.

### Causes Possibles

1. **Schéma Prisma non synchronisé** avec la structure réelle de la BD
2. **Mappings de colonnes** incorrects (@map dans schema.prisma)
3. **Client Prisma** généré pour une ancienne version de la BD
4. **Cache Prisma** contenant des métadonnées obsolètes

## ✅ SOLUTION ÉTAPE PAR ÉTAPE

### Étape 1: Vérifier que les Données Existent

```batch
# Exécuter:
verifier-schema-bd.bat
```

Ce script va:
- Afficher les tables de la BD
- Compter les données
- Extraire le schéma complet

**Résultat attendu:** Vous devez voir des nombres > 0 pour utilisateurs, produits, ventes.

### Étape 2: Tester la Lecture Prisma

```batch
# Exécuter:
tester-lecture-prisma.bat
```

Ce script teste si Prisma peut lire les données.

**Interprétation:**

| Résultat | Signification | Solution |
|----------|---------------|----------|
| Prisma trouve 0, SQL brut trouve > 0 | Problème de schéma Prisma | Étape 3 |
| Prisma trouve > 0 | Prisma fonctionne | Étape 4 |
| Tout à 0 | Base vide | Restaurer sauvegarde |

### Étape 3: Forcer la Synchronisation Prisma

```batch
# Exécuter:
forcer-synchronisation-prisma.bat
```

Ce script va:
1. Supprimer le client Prisma existant
2. Régénérer complètement le client
3. Faire une introspection de la BD (db pull)
4. Synchroniser le schéma (db push)
5. Régénérer le client final

**Temps:** 2-3 minutes

### Étape 4: Vérifier le Backend

Si Prisma lit les données mais l'app non:

```batch
# 1. Démarrer le backend
cd backend
node src/server.js

# 2. Dans un autre terminal, tester l'API
curl http://localhost:8080/api/users
curl http://localhost:8080/api/products
```

**Résultat attendu:** Vous devez voir des données JSON.

### Étape 5: Vérifier les Logs

```batch
# Consulter les logs backend
type backend\logs\error.log
type backend\logs\combined.log
```

Cherchez des erreurs comme:
- `Invalid column name`
- `Table not found`
- `Schema mismatch`
- `Prisma error`

## 🛠️ SOLUTIONS AVANCÉES

### Solution 1: Régénération Complète Prisma

```batch
cd backend

# 1. Supprimer complètement Prisma
rmdir /s /q node_modules\.prisma
rmdir /s /q node_modules\@prisma

# 2. Réinstaller
npm install @prisma/client prisma

# 3. Générer
npx prisma generate

# 4. Synchroniser
npx prisma db push --accept-data-loss

# 5. Tester
node test-prisma-connection.js
```

### Solution 2: Vérifier les Mappings de Colonnes

Le schéma Prisma utilise des mappings. Vérifiez que les noms correspondent:

```prisma
// Dans schema.prisma
model Utilisateur {
  nomUtilisateur String @map("nom_utilisateur")
  //             ↑ Nom Prisma    ↑ Nom dans la BD
}
```

Pour vérifier:

```batch
# 1. Voir les colonnes réelles dans la BD
cd backend\database
sqlite3 logesco.db "PRAGMA table_info(utilisateurs);"

# 2. Comparer avec schema.prisma
type ..\prisma\schema.prisma
```

Si les noms ne correspondent pas, deux options:

**Option A:** Modifier le schéma Prisma pour correspondre à la BD

```prisma
// Si la BD a "username" au lieu de "nom_utilisateur"
nomUtilisateur String @map("username")
```

**Option B:** Laisser Prisma introspect la BD

```batch
cd backend
npx prisma db pull --force
# Cela va réécrire schema.prisma basé sur la BD réelle
```

### Solution 3: Vérifier DATABASE_URL

```batch
# Vérifier le fichier .env
type backend\.env
```

Doit contenir:
```
DATABASE_URL="file:./database/logesco.db"
```

Si incorrect, corriger et redémarrer.

### Solution 4: Permissions Fichier

```batch
# Vérifier les permissions
icacls backend\database\logesco.db

# Donner accès complet si nécessaire
icacls backend\database\logesco.db /grant Everyone:F
```

## 🔧 SCRIPTS DE DÉPANNAGE

### Script 1: Diagnostic Complet

```batch
diagnostic-migration-donnees.bat
```

Identifie automatiquement les problèmes.

### Script 2: Synchronisation Forcée

```batch
forcer-synchronisation-prisma.bat
```

Force la synchronisation Prisma.

### Script 3: Test Lecture

```batch
tester-lecture-prisma.bat
```

Teste si Prisma peut lire les données.

### Script 4: Vérification Schéma

```batch
verifier-schema-bd.bat
```

Compare le schéma BD vs Prisma.

## 📊 CHECKLIST DE VÉRIFICATION

Cochez au fur et à mesure:

- [ ] Données présentes dans la BD (vérifié avec sqlite)
- [ ] Taille de la BD > 100 Ko
- [ ] Prisma Client généré (node_modules/.prisma/client existe)
- [ ] DATABASE_URL correct dans .env
- [ ] Test Prisma réussit (tester-lecture-prisma.bat)
- [ ] Backend démarre sans erreur
- [ ] API retourne des données (curl test)
- [ ] Logs backend sans erreur
- [ ] Application affiche les données

## 🚨 CAS PARTICULIERS

### Cas 1: Migration depuis Ancienne Version

Si vous migrez depuis une très ancienne version:

```batch
# 1. Sauvegarder
copy backend\database\logesco.db sauvegarde_avant_migration.db

# 2. Laisser Prisma recréer le schéma
cd backend
npx prisma db push --force-reset --accept-data-loss

# 3. Restaurer les données
copy ..\sauvegarde_avant_migration.db database\logesco.db

# 4. Synchroniser
npx prisma db push --accept-data-loss
```

⚠️ **ATTENTION:** `--force-reset` supprime toutes les données! C'est pourquoi on sauvegarde d'abord.

### Cas 2: Schéma Complètement Incompatible

Si le schéma est trop différent:

```batch
# 1. Exporter les données
cd backend\database
sqlite3 logesco.db ".dump" > export.sql

# 2. Créer nouvelle BD avec bon schéma
cd ..
npx prisma db push --force-reset

# 3. Importer les données (nécessite adaptation manuelle)
# Éditer export.sql pour correspondre au nouveau schéma
sqlite3 database\logesco.db < export_adapte.sql
```

### Cas 3: Données Corrompues

Si la BD est corrompue:

```batch
# 1. Vérifier l'intégrité
cd backend\database
sqlite3 logesco.db "PRAGMA integrity_check;"

# 2. Si corrompu, essayer de réparer
sqlite3 logesco.db ".recover" | sqlite3 logesco_repare.db

# 3. Remplacer
copy logesco_repare.db logesco.db
```

## 💡 PRÉVENTION

Pour éviter ce problème à l'avenir:

### 1. Toujours Synchroniser Après Migration

Ajouter dans le script de migration:

```batch
cd backend
npx prisma generate
npx prisma db push --accept-data-loss
```

### 2. Tester Immédiatement

Après chaque migration:

```batch
tester-lecture-prisma.bat
```

### 3. Garder les Sauvegardes

Toujours garder:
- Sauvegarde avant migration
- Sauvegarde après migration réussie
- Pendant au moins 1 semaine

## 📞 SUPPORT

Si le problème persiste après avoir suivi ce guide:

1. **Collecter les informations:**
   ```batch
   # Exécuter tous les diagnostics
   diagnostic-migration-donnees.bat > diagnostic.txt
   verifier-schema-bd.bat > schema.txt
   tester-lecture-prisma.bat > test-prisma.txt
   ```

2. **Vérifier les logs:**
   ```batch
   type backend\logs\error.log > logs-error.txt
   ```

3. **Envoyer au support:**
   - diagnostic.txt
   - schema.txt
   - test-prisma.txt
   - logs-error.txt
   - backend\database\schema_actuel.txt

## ✅ RÉSUMÉ

**Problème:** Données dans la BD mais pas dans l'app

**Cause:** Schéma Prisma non synchronisé

**Solution rapide:**
```batch
forcer-synchronisation-prisma.bat
```

**Vérification:**
```batch
tester-lecture-prisma.bat
```

**Si ça ne marche toujours pas:** Suivre les solutions avancées ci-dessus.

---

**Version:** 1.0  
**Date:** 2026-03-06  
**Testé:** Windows 10/11
