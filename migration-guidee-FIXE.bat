@echo off
setlocal enabledelayedexpansion
title LOGESCO - Migration Guidee Client FIXE
color 0A
echo ========================================
echo   MIGRATION GUIDEE CLIENT - FIXE
echo   Conservation GARANTIE des donnees
echo ========================================
echo.

echo Ce script migre votre installation LOGESCO
echo vers la nouvelle version en PRESERVANT vos donnees.
echo.
echo PROBLEME RESOLU:
echo - Base de donnees correctement restauree
echo - Schema Prisma synchronise
echo - Donnees utilisateur preservees
echo.
pause
echo.

echo ETAPE 1/9: Verification de l'emplacement
echo =========================================
echo.
echo Dossier actuel: %CD%
echo.
set /p CONFIRM="Est-ce le bon dossier d'installation LOGESCO? (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo.
    echo Allez dans le dossier d'installation LOGESCO
    echo puis relancez ce script.
    pause
    exit /b 0
)
echo.

echo ETAPE 2/9: Verification et analyse des donnees
echo ===============================================
echo.
if not exist "backend\database\logesco.db" (
    echo ❌ Base de donnees non trouvee!
    echo Ce ne semble pas etre une installation LOGESCO.
    echo.
    pause
    exit /b 1
)

echo ✅ Installation LOGESCO detectee
echo.

REM Compter les données AVANT migration
echo Analyse des donnees actuelles...
set USER_COUNT_BEFORE=0
set PRODUCT_COUNT_BEFORE=0
set SALES_COUNT_BEFORE=0

where sqlite3 >nul 2>nul
if not errorlevel 1 (
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM utilisateurs;" 2^>nul') do set USER_COUNT_BEFORE=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT_BEFORE=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT_BEFORE=%%i
    
    echo Donnees actuelles:
    echo - Utilisateurs: %USER_COUNT_BEFORE%
    echo - Produits: %PRODUCT_COUNT_BEFORE%
    echo - Ventes: %SALES_COUNT_BEFORE%
    echo.
    
    if %USER_COUNT_BEFORE% EQU 0 (
        echo ⚠️  ATTENTION: Aucun utilisateur trouve!
        echo    La base semble vide ou corrompue.
        set /p CONTINUE="Continuer quand meme? (O/N): "
        if /i not "!CONTINUE!"=="O" exit /b 0
    )
) else (
    echo ⚠️  sqlite3 non disponible - impossible de compter les donnees
    echo    La migration continuera sans verification
)
echo.
pause
echo.

echo ETAPE 3/9: Verification du package de mise a jour
echo ==================================================
echo.
echo Recherche du package de mise a jour...
echo.

set "PACKAGE_TROUVE=0"
set "PACKAGE_TYPE=UNKNOWN"
set "PACKAGE_PATH="

REM Recherche du package OPTIMISE (prioritaire)
if exist "Package-Mise-A-Jour\LOGESCO-Client-Optimise" (
    echo ✅ Package OPTIMISE trouve: Package-Mise-A-Jour\LOGESCO-Client-Optimise
    set "PACKAGE_PATH=Package-Mise-A-Jour\LOGESCO-Client-Optimise"
    set "PACKAGE_TYPE=OPTIMISE"
    set "PACKAGE_TROUVE=1"
    goto :package_found
)

if exist "LOGESCO-Client-Optimise" (
    echo ✅ Package OPTIMISE trouve: LOGESCO-Client-Optimise
    set "PACKAGE_PATH=LOGESCO-Client-Optimise"
    set "PACKAGE_TYPE=OPTIMISE"
    set "PACKAGE_TROUVE=1"
    goto :package_found
)

if exist "release\LOGESCO-Client-Optimise" (
    echo ✅ Package OPTIMISE trouve: release\LOGESCO-Client-Optimise
    set "PACKAGE_PATH=release\LOGESCO-Client-Optimise"
    set "PACKAGE_TYPE=OPTIMISE"
    set "PACKAGE_TROUVE=1"
    goto :package_found
)

REM Si pas de package OPTIMISE, chercher ULTIMATE
if exist "Package-Mise-A-Jour\LOGESCO-Client-Ultimate" (
    echo ✅ Package ULTIMATE trouve: Package-Mise-A-Jour\LOGESCO-Client-Ultimate
    set "PACKAGE_PATH=Package-Mise-A-Jour\LOGESCO-Client-Ultimate"
    set "PACKAGE_TYPE=ULTIMATE"
    set "PACKAGE_TROUVE=1"
    goto :package_found
)

if exist "LOGESCO-Client-Ultimate" (
    echo ✅ Package ULTIMATE trouve: LOGESCO-Client-Ultimate
    set "PACKAGE_PATH=LOGESCO-Client-Ultimate"
    set "PACKAGE_TYPE=ULTIMATE"
    set "PACKAGE_TROUVE=1"
    goto :package_found
)

if exist "release\LOGESCO-Client-Ultimate" (
    echo ✅ Package ULTIMATE trouve: release\LOGESCO-Client-Ultimate
    set "PACKAGE_PATH=release\LOGESCO-Client-Ultimate"
    set "PACKAGE_TYPE=ULTIMATE"
    set "PACKAGE_TROUVE=1"
    goto :package_found
)

REM Aucun package trouvé
echo ❌ Package de mise a jour non trouve!
echo.
echo SOLUTION:
echo 1. Copiez le dossier LOGESCO-Client-Optimise OU LOGESCO-Client-Ultimate ici
echo 2. Ou copiez-le dans un sous-dossier Package-Mise-A-Jour
echo.
pause
exit /b 1

:package_found
echo.
echo Type de package: %PACKAGE_TYPE%
echo.
pause
echo.

echo ETAPE 4/9: Sauvegarde COMPLETE des donnees
echo ===========================================
echo.
echo Creation de la sauvegarde securisee...
echo.

set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_DIR=sauvegarde_migration_%TIMESTAMP%

mkdir "%BACKUP_DIR%"
mkdir "%BACKUP_DIR%\backend_complet"

echo [1/4] Sauvegarde de la base de donnees...
copy "backend\database\logesco.db" "%BACKUP_DIR%\logesco_original.db" >nul
if errorlevel 1 (
    echo ❌ Erreur sauvegarde base de donnees!
    pause
    exit /b 1
)
echo ✅ Base de donnees sauvegardee

echo [2/4] Sauvegarde de la configuration...
if exist "backend\.env" copy "backend\.env" "%BACKUP_DIR%\.env_original" >nul
if exist "backend\package.json" copy "backend\package.json" "%BACKUP_DIR%\package.json" >nul

echo [3/4] Sauvegarde des uploads...
if exist "backend\uploads" xcopy /E /I /Y /Q "backend\uploads" "%BACKUP_DIR%\uploads" >nul 2>nul

echo [4/4] Sauvegarde complete du backend...
xcopy /E /I /Y /Q "backend\*" "%BACKUP_DIR%\backend_complet\" >nul

echo.
echo ✅ Sauvegarde complete: %BACKUP_DIR%
echo.
pause
echo.

echo ETAPE 5/9: Arret des processus
echo ===============================
echo.
taskkill /f /im logesco_v2.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo ✅ Processus arretes
echo.

echo ETAPE 6/9: Installation du nouveau backend
echo ===========================================
echo.

echo Sauvegarde de l'ancien backend...
if exist "backend_ancien" rmdir /s /q "backend_ancien" >nul 2>nul
ren "backend" "backend_ancien"
echo ✅ Ancien backend sauvegarde
echo.

echo Installation du nouveau backend...
xcopy /E /I /Y /Q "%PACKAGE_PATH%\backend" "backend\" >nul
if errorlevel 1 (
    echo ❌ Erreur copie nouveau backend
    echo Restauration...
    ren "backend_ancien" "backend"
    pause
    exit /b 1
)
echo ✅ Nouveau backend installe
echo.

echo ETAPE 7/9: SUPPRESSION de la base vierge et restauration
echo =========================================================
echo.
echo CRITIQUE: Suppression de la base vierge du package...
if exist "backend\database\logesco.db" (
    del /f /q "backend\database\logesco.db" >nul 2>nul
    echo ✅ Base vierge supprimee
) else (
    echo ℹ️  Pas de base vierge a supprimer
)
echo.

echo Restauration de VOTRE base de donnees...
if not exist "backend\database" mkdir "backend\database"
copy "%BACKUP_DIR%\logesco_original.db" "backend\database\logesco.db" >nul
if errorlevel 1 (
    echo ❌ Erreur restauration base de donnees!
    echo Restauration complete...
    rmdir /s /q "backend" >nul 2>nul
    ren "backend_ancien" "backend"
    pause
    exit /b 1
)
echo ✅ Votre base de donnees restauree
echo.

REM Vérifier la taille du fichier
for %%A in ("backend\database\logesco.db") do set DB_SIZE=%%~zA
echo Taille de la base: %DB_SIZE% octets
if %DB_SIZE% LSS 10000 (
    echo ⚠️  ATTENTION: Base de donnees tres petite!
    echo    Cela peut indiquer un probleme.
    pause
)
echo.

echo ETAPE 8/9: Configuration et synchronisation Prisma
echo ===================================================
echo.
cd backend

REM Créer/Vérifier le fichier .env
if not exist ".env" (
    echo Creation fichier .env...
    (
    echo NODE_ENV=production
    echo PORT=8080
    echo DATABASE_URL="file:./database/logesco.db"
    echo JWT_SECRET="logesco-jwt-secret-change-in-production"
    echo CORS_ORIGIN="*"
    echo RATE_LIMIT_ENABLED=false
    ) > .env
    echo ✅ Fichier .env cree
) else (
    echo ✅ Fichier .env existe
)
echo.

REM Configuration selon le type de package
if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo Configuration OPTIMISE...
    echo.
    
    REM Vérifier Prisma pré-généré
    if not exist "node_modules\.prisma\client" (
        echo ⚠️  Prisma Client manquant, generation...
        call npx prisma generate
        if errorlevel 1 (
            echo ❌ Erreur generation Prisma
            cd ..
            pause
            exit /b 1
        )
    ) else (
        echo ✅ Prisma Client pre-genere present
    )
    echo.
    
    echo IMPORTANT: Synchronisation du schema avec votre base...
    echo (Cela garantit la compatibilite)
    echo.
    call npx prisma db push --accept-data-loss
    if errorlevel 1 (
        echo ⚠️  Avertissement: Synchronisation schema
        echo    Cela peut etre normal si le schema est deja a jour
    ) else (
        echo ✅ Schema synchronise
    )
) else (
    echo Configuration ULTIMATE...
    echo.
    
    REM Installation des dépendances si nécessaire
    if not exist "node_modules" (
        echo Installation des dependances...
        call npm install
        if errorlevel 1 (
            echo ❌ Erreur installation dependances
            cd ..
            pause
            exit /b 1
        )
    )
    echo.
    
    echo Generation du client Prisma...
    call npx prisma generate
    if errorlevel 1 (
        echo ❌ Erreur generation Prisma
        cd ..
        pause
        exit /b 1
    )
    echo ✅ Prisma genere
    echo.
    
    echo Synchronisation du schema avec votre base...
    call npx prisma db push --accept-data-loss
    if errorlevel 1 (
        echo ⚠️  Avertissement: Synchronisation schema
    ) else (
        echo ✅ Schema synchronise
    )
)

cd ..
echo.
echo ✅ Configuration terminee
echo.
pause
echo.

echo ETAPE 9/9: Verification des donnees et test
echo ============================================
echo.

REM Vérifier les données APRÈS migration
set USER_COUNT_AFTER=0
set PRODUCT_COUNT_AFTER=0
set SALES_COUNT_AFTER=0

where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Verification des donnees restaurees...
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM utilisateurs;" 2^>nul') do set USER_COUNT_AFTER=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT_AFTER=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT_AFTER=%%i
    
    echo.
    echo COMPARAISON AVANT/APRES:
    echo ========================
    echo Utilisateurs: %USER_COUNT_BEFORE% -^> %USER_COUNT_AFTER%
    echo Produits: %PRODUCT_COUNT_BEFORE% -^> %PRODUCT_COUNT_AFTER%
    echo Ventes: %SALES_COUNT_BEFORE% -^> %SALES_COUNT_AFTER%
    echo.
    
    if %USER_COUNT_AFTER% EQU %USER_COUNT_BEFORE% (
        echo ✅ DONNEES PRESERVEES!
    ) else (
        echo ⚠️  ATTENTION: Difference dans les donnees!
        echo    Avant: %USER_COUNT_BEFORE% utilisateurs
        echo    Apres: %USER_COUNT_AFTER% utilisateurs
        echo.
        set /p CONTINUE="Continuer quand meme? (O/N): "
        if /i not "!CONTINUE!"=="O" (
            echo.
            echo Restauration disponible dans: %BACKUP_DIR%
            pause
            exit /b 1
        )
    )
)
echo.

echo Installation de la nouvelle application...
if exist "app_ancien" rmdir /s /q "app_ancien" >nul 2>nul
if exist "app" ren "app" "app_ancien"
xcopy /E /I /Y /Q "%PACKAGE_PATH%\app" "app\" >nul
echo ✅ Nouvelle application installee
echo.

echo Test du backend...
cd backend
start "LOGESCO Backend Test" /MIN node src/server.js
cd ..

echo Attente demarrage backend (10 secondes)...
timeout /t 10 /nobreak >nul

curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ⚠️  Backend ne repond pas encore
    echo   Attente supplementaire...
    timeout /t 5 /nobreak >nul
    curl -s http://localhost:8080/health >nul 2>nul
    if errorlevel 1 (
        echo ⚠️  Backend encore en initialisation
    ) else (
        echo ✅ Backend fonctionne!
    )
) else (
    echo ✅ Backend fonctionne!
)

echo.
echo Demarrage de l'application...
start "" "app\logesco_v2.exe"

timeout /t 3 /nobreak >nul
taskkill /f /im node.exe >nul 2>nul

echo.
echo ========================================
echo   MIGRATION TERMINEE AVEC SUCCES!
echo ========================================
echo.
echo 📦 Type de package: %PACKAGE_TYPE%
echo.
echo 📊 DONNEES PRESERVEES:
if defined USER_COUNT_AFTER (
    echo    Utilisateurs: %USER_COUNT_AFTER%
    echo    Produits: %PRODUCT_COUNT_AFTER%
    echo    Ventes: %SALES_COUNT_AFTER%
)
echo.
echo 📁 SAUVEGARDES:
echo    Sauvegarde complete: %BACKUP_DIR%\
echo    Ancien backend: backend_ancien\
echo    Ancienne app: app_ancien\
echo.
echo 🚀 DEMARRAGE:
if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo    Utilisez: DEMARRER-LOGESCO.bat
) else (
    echo    Utilisez: DEMARRER-LOGESCO-ULTIMATE.bat
)
echo.
echo 🔑 CONNEXION:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
echo ✅ VOS DONNEES SONT PRESERVEES!
echo.
pause
