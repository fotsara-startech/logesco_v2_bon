# Guide de Migration Client - Préservation des Données

## 🚨 PROBLÈME CONNU

Si vous utilisez le script `migration-guidee.bat` standard, **VOS DONNÉES SERONT PERDUES** car le package contient une base de données vierge qui écrase vos données.

## ✅ SOLUTION RAPIDE

### Utilisez le script corrigé: `migration-guidee-FIXE.bat`

```batch
# Depuis le dossier d'installation LOGESCO
migration-guidee-FIXE.bat
```

Ce script:
- ✅ Sauvegarde vos données AVANT tout
- ✅ Supprime la base vierge du package
- ✅ Restaure VOS données
- ✅ Synchronise automatiquement
- ✅ Vérifie que tout est OK

## 📋 ÉTAPES SIMPLES

### 1. Préparation (2 minutes)

```batch
# Aller dans le dossier d'installation LOGESCO
cd C:\LOGESCO

# Vérifier que vous avez des données
dir backend\database\logesco.db
```

La taille doit être > 100 Ko si vous avez des données.

### 2. Copier le Package de Mise à Jour

```
C:\LOGESCO\
├── backend\
├── app\
└── Package-Mise-A-Jour\
    └── LOGESCO-Client-Optimise\  ← Copier ici
```

### 3. Lancer la Migration

```batch
# Double-cliquer sur:
migration-guidee-FIXE.bat
```

Suivez les instructions à l'écran.

### 4. Vérification

Le script affiche:
```
COMPARAISON AVANT/APRES:
========================
Utilisateurs: 5 -> 5
Produits: 150 -> 150
Ventes: 320 -> 320

✅ DONNEES PRESERVEES!
```

## 🔧 EN CAS DE PROBLÈME

### Problème: "Base de données à 0"

**Diagnostic:**
```batch
diagnostic-migration-donnees.bat
```

**Solution rapide:**
```batch
# 1. Trouver la sauvegarde
dir sauvegarde_migration_*

# 2. Restaurer
copy sauvegarde_migration_XXXXXXXX\logesco_original.db backend\database\logesco.db

# 3. Synchroniser
cd backend
npx prisma db push --accept-data-loss
cd ..

# 4. Redémarrer
cd backend
node src/server.js
```

### Problème: "Erreur Prisma"

```batch
cd backend
npx prisma generate
npx prisma db push --accept-data-loss
cd ..
```

### Problème: "Backend ne démarre pas"

```batch
# Vérifier le fichier .env
type backend\.env

# Doit contenir:
# DATABASE_URL="file:./database/logesco.db"
```

## 📞 SUPPORT

### Scripts Disponibles

1. **migration-guidee-FIXE.bat** - Migration avec préservation des données
2. **diagnostic-migration-donnees.bat** - Identifier les problèmes
3. **SOLUTION_PROBLEME_MIGRATION_DONNEES.md** - Guide détaillé

### Vérifications Manuelles

```batch
# Compter les données
cd backend\database
sqlite3 logesco.db "SELECT COUNT(*) FROM utilisateurs;"
sqlite3 logesco.db "SELECT COUNT(*) FROM produits;"

# Vérifier la taille
dir logesco.db

# Tester le backend
cd ..
node src/server.js
# Ouvrir: http://localhost:8080/health
```

## ⚠️ IMPORTANT

### À FAIRE

- ✅ Utiliser `migration-guidee-FIXE.bat`
- ✅ Vérifier les données avant/après
- ✅ Garder les sauvegardes 1 semaine
- ✅ Tester avant de supprimer les sauvegardes

### À NE PAS FAIRE

- ❌ Utiliser `migration-guidee.bat` (ancien script)
- ❌ Copier manuellement sans synchroniser Prisma
- ❌ Supprimer les sauvegardes immédiatement
- ❌ Ignorer les avertissements du script

## 🎯 RÉSUMÉ

**Problème:** Le package contient une base vierge qui écrase vos données

**Solution:** Le script `migration-guidee-FIXE.bat` supprime la base vierge et restaure vos données

**Temps:** 5-10 minutes

**Sécurité:** Sauvegardes automatiques + vérifications

---

**Version:** 1.0  
**Date:** 2026-03-06  
**Testé sur:** Windows 10/11
