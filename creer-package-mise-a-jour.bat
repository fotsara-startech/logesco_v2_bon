@echo off
title LOGESCO - Creation Package Mise a Jour Client
echo ========================================
echo   CREATION PACKAGE MISE A JOUR CLIENT
echo ========================================
echo.

echo Ce script cree le package complet pour
echo mettre a jour un client existant.
echo.
pause
echo.

echo [1/5] Verification des prerequis...
if not exist "release\LOGESCO-Client-Ultimate" (
    echo ❌ ERREUR: Nouvelle version non trouvee
    echo.
    echo Construisez d'abord la nouvelle version:
    echo preparer-pour-client-ultimate.bat
    echo.
    pause
    exit /b 1
)

if not exist "sauvegarder-donnees-client.bat" (
    echo ❌ ERREUR: Scripts de migration manquants
    pause
    exit /b 1
)

echo ✅ Tous les prerequis sont presents
echo.

echo [2/5] Creation du dossier package...
set PACKAGE_DIR=Package-Mise-A-Jour-Client
if exist "%PACKAGE_DIR%" (
    echo Suppression de l'ancien package...
    rmdir /s /q "%PACKAGE_DIR%" >nul 2>nul
)

mkdir "%PACKAGE_DIR%"
echo ✅ Dossier package cree: %PACKAGE_DIR%
echo.

echo [3/5] Copie de la nouvelle version...
echo Copie de LOGESCO-Client-Ultimate...
xcopy /E /I /Y /Q "release\LOGESCO-Client-Ultimate" "%PACKAGE_DIR%\LOGESCO-Client-Ultimate" >nul
if errorlevel 1 (
    echo ❌ Erreur copie nouvelle version
    pause
    exit /b 1
)
echo ✅ Nouvelle version copiee
echo.

echo [4/5] Copie des scripts de migration...
copy "sauvegarder-donnees-client.bat" "%PACKAGE_DIR%\" >nul
copy "migrer-client-existant.bat" "%PACKAGE_DIR%\" >nul
copy "valider-migration.bat" "%PACKAGE_DIR%\" >nul
copy "restaurer-ancienne-version.bat" "%PACKAGE_DIR%\" >nul

if exist "ORDRE_ETAPES_MISE_A_JOUR.md" (
    copy "ORDRE_ETAPES_MISE_A_JOUR.md" "%PACKAGE_DIR%\" >nul
)

echo ✅ Scripts de migration copies
echo.

echo [5/5] Creation de la documentation...

REM Instructions pour le client
(
echo INSTRUCTIONS DE MISE A JOUR LOGESCO
echo ===================================
echo.
echo IMPORTANT: Suivez ces etapes dans l'ordre exact!
echo.
echo ETAPE 1: SAUVEGARDE ^(OBLIGATOIRE^)
echo =====================================
echo 1. Allez dans le dossier ou LOGESCO est installe
echo 2. Copiez sauvegarder-donnees-client.bat dans ce dossier
echo 3. Executez: sauvegarder-donnees-client.bat
echo 4. Attendez la fin de la sauvegarde
echo.
echo ETAPE 2: INSTALLATION NOUVELLE VERSION
echo ======================================
echo 1. Copiez le dossier LOGESCO-Client-Ultimate a cote de l'ancien
echo 2. Copiez tous les fichiers .bat dans le dossier d'installation
echo.
echo ETAPE 3: MIGRATION
echo ==================
echo 1. Executez: migrer-client-existant.bat
echo 2. Attendez la fin de la migration
echo 3. Ne fermez pas la fenetre en cas d'erreur
echo.
echo ETAPE 4: VALIDATION
echo ===================
echo 1. Executez: valider-migration.bat
echo 2. Verifiez que toutes les donnees sont presentes
echo 3. Testez les fonctionnalites principales
echo.
echo ETAPE 5: EN CAS DE PROBLEME
echo ===========================
echo 1. Executez: restaurer-ancienne-version.bat
echo 2. Contactez le support technique
echo 3. Conservez tous les dossiers de sauvegarde
echo.
echo SUPPORT TECHNIQUE
echo =================
echo En cas de probleme, conservez:
echo - Le dossier sauvegarde_client_*
echo - Les messages d'erreur exacts
echo - Le fichier de log si disponible
echo.
echo NOUVELLES FONCTIONNALITES
echo =========================
echo - Interface modernisee
echo - Gestion avancee des inventaires
echo - Systeme de permissions granulaires
echo - Rapports detailles
echo - Gestion des caisses multiples
echo - Suivi des mouvements financiers
echo - Performance amelioree
echo - Securite renforcee
echo.
echo Temps estime: 1h30 a 2h30
echo Donnees preservees: 100%%
) > "%PACKAGE_DIR%\INSTRUCTIONS_MISE_A_JOUR.txt"

REM Changelog détaillé
(
echo LOGESCO v2 - NOUVELLES FONCTIONNALITES
echo ======================================
echo.
echo INTERFACE UTILISATEUR
echo =====================
echo ✅ Design modernise et intuitif
echo ✅ Navigation amelioree
echo ✅ Interface responsive
echo ✅ Themes visuels
echo.
echo GESTION DES STOCKS
echo ==================
echo ✅ Inventaires avances avec comptage
echo ✅ Mouvements de stock detailles
echo ✅ Alertes de stock minimum
echo ✅ Historique complet des mouvements
echo.
echo GESTION DES VENTES
echo ==================
echo ✅ Interface de vente amelioree
echo ✅ Gestion des remises avancee
echo ✅ Factures et recus personnalises
echo ✅ Suivi des paiements clients
echo.
echo GESTION DES CAISSES
echo ===================
echo ✅ Caisses multiples
echo ✅ Sessions de caisse
echo ✅ Rapprochement automatique
echo ✅ Historique des mouvements
echo.
echo RAPPORTS ET ANALYSES
echo ====================
echo ✅ Rapports de ventes detailles
echo ✅ Analyses de rentabilite
echo ✅ Statistiques en temps reel
echo ✅ Export Excel/PDF
echo.
echo SECURITE ET PERMISSIONS
echo =======================
echo ✅ Systeme de roles granulaires
echo ✅ Permissions par module
echo ✅ Audit des actions utilisateur
echo ✅ Sauvegarde automatique
echo.
echo PERFORMANCE
echo ===========
echo ✅ Vitesse d'execution amelioree
echo ✅ Interface plus fluide
echo ✅ Gestion optimisee de la memoire
echo ✅ Demarrage plus rapide
echo.
echo COMPATIBILITE
echo =============
echo ✅ Windows 10/11
echo ✅ Migration automatique des donnees
echo ✅ Preservation complete des informations
echo ✅ Rollback possible en cas de probleme
) > "%PACKAGE_DIR%\NOUVELLES_FONCTIONNALITES.txt"

REM Script de démarrage pour le technicien
(
echo @echo off
echo title LOGESCO - Assistant Mise a Jour
echo echo ========================================
echo echo   ASSISTANT MISE A JOUR LOGESCO
echo echo ========================================
echo echo.
echo echo Ce script guide la mise a jour chez le client.
echo echo.
echo echo ETAPES A SUIVRE:
echo echo 1. Aller dans le dossier d'installation client
echo echo 2. Copier sauvegarder-donnees-client.bat
echo echo 3. Executer la sauvegarde
echo echo 4. Copier la nouvelle version
echo echo 5. Executer la migration
echo echo 6. Valider le resultat
echo echo.
echo echo Consultez INSTRUCTIONS_MISE_A_JOUR.txt pour les details.
echo echo.
echo pause
) > "%PACKAGE_DIR%\ASSISTANT_MISE_A_JOUR.bat"

echo ✅ Documentation creee
echo.

REM Calculer la taille du package
echo Calcul de la taille du package...
for /f %%i in ('dir "%PACKAGE_DIR%" /s /-c ^| find "bytes"') do set PACKAGE_SIZE=%%i

echo ========================================
echo   PACKAGE MISE A JOUR CREE AVEC SUCCES
echo ========================================
echo.
echo 📦 Package: %PACKAGE_DIR%\
echo 📊 Taille: %PACKAGE_SIZE% octets
echo.
echo 📂 CONTENU:
echo ✅ LOGESCO-Client-Ultimate\          ^(Nouvelle version complete^)
echo ✅ sauvegarder-donnees-client.bat    ^(Sauvegarde^)
echo ✅ migrer-client-existant.bat        ^(Migration^)
echo ✅ valider-migration.bat             ^(Validation^)
echo ✅ restaurer-ancienne-version.bat    ^(Rollback^)
echo ✅ INSTRUCTIONS_MISE_A_JOUR.txt      ^(Guide client^)
echo ✅ NOUVELLES_FONCTIONNALITES.txt     ^(Changelog^)
echo ✅ ASSISTANT_MISE_A_JOUR.bat         ^(Guide technicien^)
echo.
echo 🚀 PRET POUR DEPLOIEMENT CLIENT!
echo.
echo PROCHAINES ETAPES:
echo 1. Transporter ce package chez le client
echo 2. Suivre les instructions dans INSTRUCTIONS_MISE_A_JOUR.txt
echo 3. Executer ASSISTANT_MISE_A_JOUR.bat pour guidance
echo.
echo ⏱️ Temps estime chez le client: 1h30 a 2h30
echo 🛡️ Donnees client: 100%% preservees
echo.
pause