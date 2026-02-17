# Ordre Exact des Étapes - Mise à Jour Client

## Phase 1 : PRÉPARATION (Chez vous - Avant d'aller chez le client)

### 1.1 Construire la nouvelle version
```bash
# Construire le package portable complet
preparer-pour-client-ultimate.bat
```
**Résultat :** Dossier `release/LOGESCO-Client-Ultimate/`

### 1.2 Créer le package de mise à jour
Créer un dossier `Package-Mise-A-Jour-Client/` contenant :
```
Package-Mise-A-Jour-Client/
├── LOGESCO-Client-Ultimate/           # Nouvelle version complète
├── sauvegarder-donnees-client.bat     # Script sauvegarde
├── migrer-client-existant.bat         # Script migration
├── valider-migration.bat              # Script validation
├── restaurer-ancienne-version.bat     # Script rollback
├── INSTRUCTIONS_MISE_A_JOUR.txt       # Guide pour le client
└── NOUVELLES_FONCTIONNALITES.txt      # Changelog
```

### 1.3 Transporter chez le client
- Clé USB, disque dur externe, ou téléchargement
- Apporter le dossier `Package-Mise-A-Jour-Client/` complet

## Phase 2 : CHEZ LE CLIENT (Ordre strict à respecter)

### Étape 1 : SAUVEGARDE (Dans le dossier de l'ancienne installation)
```bash
# Se placer dans le dossier où LOGESCO est installé chez le client
cd "C:\LOGESCO" (ou autre chemin)

# Copier le script de sauvegarde
copy "Package-Mise-A-Jour-Client\sauvegarder-donnees-client.bat" .

# Exécuter la sauvegarde
sauvegarder-donnees-client.bat
```
**Résultat :** Dossier `sauvegarde_client_YYYYMMDD_HHMMSS/` créé

### Étape 2 : COPIER LA NOUVELLE VERSION
```bash
# Copier la nouvelle version à côté de l'ancienne
xcopy /E /I "Package-Mise-A-Jour-Client\LOGESCO-Client-Ultimate" "LOGESCO-Nouveau"

# Copier les scripts de migration
copy "Package-Mise-A-Jour-Client\migrer-client-existant.bat" .
copy "Package-Mise-A-Jour-Client\valider-migration.bat" .
copy "Package-Mise-A-Jour-Client\restaurer-ancienne-version.bat" .
```

### Étape 3 : MIGRATION
```bash
# Exécuter la migration (dans le dossier de l'ancienne installation)
migrer-client-existant.bat
```
**Actions automatiques :**
- Analyse de l'ancienne BD
- Migration des données vers le nouveau schéma
- Remplacement des fichiers
- Configuration automatique

### Étape 4 : VALIDATION
```bash
# Valider que tout fonctionne
valider-migration.bat
```

### Étape 5 : TEST UTILISATEUR
- Démarrer LOGESCO
- Tester la connexion (admin/admin123)
- Vérifier que les données sont présentes
- Tester les fonctionnalités principales

### Étape 6 : FORMATION (Si tout fonctionne)
- Présenter les nouvelles fonctionnalités
- Former l'utilisateur aux changements
- Laisser la documentation

### Étape 7 : NETTOYAGE (Optionnel)
```bash
# Si tout fonctionne parfaitement après quelques jours
rmdir /s /q "backend_ancien"
rmdir /s /q "sauvegarde_client_*"
rmdir /s /q "LOGESCO-Nouveau"
```

## Phase 3 : EN CAS DE PROBLÈME

### Si problème pendant la migration
```bash
# Restaurer immédiatement
restaurer-ancienne-version.bat
```

### Si problème après validation
```bash
# Analyser le problème
# Si critique : restaurer
restaurer-ancienne-version.bat
```

## STRUCTURE FINALE CHEZ LE CLIENT

### Pendant la migration :
```
C:\LOGESCO\                           # Dossier d'installation client
├── backend\                          # Nouveau backend (après migration)
├── app\                             # Nouvelle application
├── backend_ancien\                   # Ancien backend (sauvegarde)
├── sauvegarde_client_YYYYMMDD\      # Sauvegarde complète
├── LOGESCO-Nouveau\                 # Copie de la nouvelle version
├── migrer-client-existant.bat       # Scripts de migration
├── valider-migration.bat            
├── restaurer-ancienne-version.bat   
└── DEMARRER-LOGESCO-ULTIMATE.bat    # Nouveau script de démarrage
```

### Après nettoyage (si tout fonctionne) :
```
C:\LOGESCO\                           # Dossier d'installation client
├── backend\                          # Nouveau backend
├── app\                             # Nouvelle application
├── vcredist\                        # Visual C++ Redistributable
├── DEMARRER-LOGESCO-ULTIMATE.bat    # Script de démarrage
├── ARRETER-LOGESCO-ULTIMATE.bat     # Script d'arrêt
├── VERIFIER-PREREQUIS.bat           # Diagnostic
└── README.txt                       # Documentation
```