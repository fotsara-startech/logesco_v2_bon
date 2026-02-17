# Guide Simple - Migration Client

## Problème Rencontré
Vous avez eu l'erreur : "Nouveau backend non trouvé dans dist-portable"

## Cause
Le package de mise à jour n'était pas au bon endroit.

## Solution Simple en 3 Étapes

### CHEZ VOUS (Préparation)

#### 1. Créer le package complet
```bash
preparer-pour-client-ultimate.bat
```
**Résultat :** `release/LOGESCO-Client-Ultimate/`

#### 2. Copier sur clé USB
Copiez le dossier `release/LOGESCO-Client-Ultimate/` sur votre clé USB

### CHEZ LE CLIENT

#### 3. Utiliser le script de migration guidée
```bash
# 1. Aller dans le dossier d'installation LOGESCO du client
cd "C:\LOGESCO"  # (ou autre chemin)

# 2. Copier le nouveau package depuis la clé USB
xcopy /E /I "E:\LOGESCO-Client-Ultimate" "LOGESCO-Client-Ultimate"

# 3. Copier le script de migration guidée
copy "E:\migration-guidee.bat" .

# 4. Exécuter la migration guidée
migration-guidee.bat
```

## Script de Migration Guidée

Le script `migration-guidee.bat` fait TOUT automatiquement :
- ✅ Vérifie l'installation existante
- ✅ Cherche le package de mise à jour
- ✅ Sauvegarde les données
- ✅ Installe la nouvelle version
- ✅ Restaure les données
- ✅ Configure automatiquement
- ✅ Teste le résultat

## Emplacements Acceptés pour le Package

Le script cherche automatiquement dans :
1. `Package-Mise-A-Jour\LOGESCO-Client-Ultimate\`
2. `LOGESCO-Client-Ultimate\`
3. `release\LOGESCO-Client-Ultimate\`

## Structure Attendue

```
C:\LOGESCO\                              # Installation client existante
├── backend\                             # Ancien backend
├── app\                                 # Ancienne app
├── LOGESCO-Client-Ultimate\             # Nouveau package copié
│   ├── backend\                         # Nouveau backend
│   ├── app\                             # Nouvelle app
│   └── ...
└── migration-guidee.bat                 # Script de migration
```

## Commandes Rapides

### Préparation (chez vous)
```bash
preparer-pour-client-ultimate.bat
```

### Migration (chez le client)
```bash
# Copier le package
xcopy /E /I "E:\LOGESCO-Client-Ultimate" "LOGESCO-Client-Ultimate"

# Lancer la migration
migration-guidee.bat
```

## En Cas de Problème

### Si le package n'est pas trouvé
```bash
# Vérifier que le dossier existe
dir LOGESCO-Client-Ultimate

# Si non, copier depuis la clé USB
xcopy /E /I "E:\LOGESCO-Client-Ultimate" "LOGESCO-Client-Ultimate"
```

### Si la migration échoue
Le script crée automatiquement des sauvegardes :
- `sauvegarde_migration_YYYYMMDD_HHMMSS/` - Sauvegarde complète
- `backend_ancien/` - Ancien backend
- `app_ancien/` - Ancienne application

Pour restaurer :
```bash
# Supprimer le nouveau
rmdir /s /q backend
rmdir /s /q app

# Restaurer l'ancien
ren backend_ancien backend
ren app_ancien app
```

## Avantages du Script Guidé

- ✅ **Pas besoin de scripts multiples** - Un seul script fait tout
- ✅ **Recherche automatique** du package
- ✅ **Sauvegardes automatiques** avant toute modification
- ✅ **Restauration facile** en cas de problème
- ✅ **Guidage pas à pas** avec confirmations
- ✅ **Test automatique** du résultat

## Résumé Ultra-Simple

**Chez vous :**
1. `preparer-pour-client-ultimate.bat`
2. Copier `release/LOGESCO-Client-Ultimate/` sur clé USB

**Chez le client :**
1. Copier le package dans le dossier d'installation
2. Exécuter `migration-guidee.bat`
3. Suivre les instructions à l'écran

**C'est tout !** 🎯