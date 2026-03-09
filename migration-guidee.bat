@echo off
setlocal enabledelayedexpansion
title LOGESCO - Migration Guidee Client
echo ========================================
echo   MIGRATION GUIDEE CLIENT EXISTANT
echo ========================================
echo.

echo Ce script vous guide pas a pas pour migrer
echo un client existant vers la nouvelle version.
echo.
pause
echo.

echo ETAPE 1/6: Verification de l'emplacement
echo =========================================
echo.
echo Vous devez executer ce script depuis le dossier
echo d'installation LOGESCO du client.
echo.
echo Dossier actuel: %CD%
echo.
set /p CONFIRM="Est-ce le bon dossier d'installation? (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo.
    echo Allez dans le dossier d'installation LOGESCO
    echo puis relancez ce script.
    pause
    exit /b 0
)
echo.

echo ETAPE 2/6: Verification de l'ancienne installation
echo ==================================================
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

REM Compter les données si sqlite3 disponible
where sqlite3 >nul 2>nul
if not errorlevel 1 (
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM utilisateurs;" 2^>nul') do set USER_COUNT=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT=%%i
    
    echo Donnees actuelles:
    echo - Utilisateurs: %USER_COUNT%
    echo - Produits: %PRODUCT_COUNT%
    echo - Ventes: %SALES_COUNT%
)
echo.
pause
echo.

echo ETAPE 3/6: Verification du package de mise a jour
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
echo Le package doit contenir:
echo - backend\
echo - app\
echo - Scripts de demarrage
echo.
echo Packages compatibles:
echo - LOGESCO-Client-Optimise ^(Recommande - Demarrage rapide^)
echo - LOGESCO-Client-Ultimate ^(Compatible tous clients^)
echo.
pause
exit /b 1

:package_found
echo.
echo Type de package: %PACKAGE_TYPE%
if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo   - Demarrage ultra-rapide ^(7-9 secondes^)
    echo   - Prisma pre-genere
    echo   - Base de donnees vierge
)
if "%PACKAGE_TYPE%"=="ULTIMATE" (
    echo   - Compatible tous environnements
    echo   - Gestion automatique Prisma
    echo   - Scripts auto-reparateurs
)
echo.
pause
echo.

echo ETAPE 4/6: Sauvegarde des donnees
echo ==================================
echo.
echo Creation de la sauvegarde...
echo.

set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_DIR=sauvegarde_migration_%TIMESTAMP%

mkdir "%BACKUP_DIR%"

echo Sauvegarde de la base de donnees...
copy "backend\database\logesco.db" "%BACKUP_DIR%\logesco_original.db" >nul
echo ✅ Base de donnees sauvegardee

echo Sauvegarde de la configuration...
if exist "backend\.env" copy "backend\.env" "%BACKUP_DIR%\.env_original" >nul

echo Sauvegarde des uploads...
if exist "backend\uploads" xcopy /E /I /Y /Q "backend\uploads" "%BACKUP_DIR%\uploads" >nul 2>nul

echo.
echo ✅ Sauvegarde complete: %BACKUP_DIR%
echo.
pause
echo.

echo ETAPE 5/6: Migration vers la nouvelle version
echo ==============================================
echo.
echo Arret des processus...
taskkill /f /im logesco_v2.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
echo ✅ Processus arretes
echo.

echo Sauvegarde de l'ancien backend...
if exist "backend_ancien" rmdir /s /q "backend_ancien" >nul 2>nul
echo Renommage backend actuel...
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

echo Restauration de la base de donnees...
copy "%BACKUP_DIR%\logesco_original.db" "backend\database\logesco.db" >nul
echo ✅ Base de donnees restauree
echo.

echo Installation de la nouvelle application...
if exist "app_ancien" rmdir /s /q "app_ancien" >nul 2>nul
if exist "app" ren "app" "app_ancien"
xcopy /E /I /Y /Q "%PACKAGE_PATH%\app" "app\" >nul
echo ✅ Nouvelle application installee
echo.

echo Configuration du nouveau backend...
cd backend

REM Configuration selon le type de package
if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo Configuration OPTIMISE detectee...
    echo   - Prisma pre-genere
    echo   - Pas de generation necessaire
    echo.
    
    REM Vérifier que Prisma est bien pré-généré
    if not exist "node_modules\.prisma\client" (
        echo ⚠️ Prisma Client manquant, generation...
        call npx prisma generate >nul 2>nul
    ) else (
        echo ✅ Prisma Client pre-genere present
    )
) else (
    echo Configuration ULTIMATE detectee...
    echo   - Generation Prisma automatique
    echo.
    
    REM Installation des dépendances si nécessaire
    if not exist "node_modules" (
        echo Installation des dependances...
        call npm install >nul 2>nul
    )
    
    REM Génération Prisma avec gestion des versions
    echo Generation du client Prisma...
    call npx prisma@6.17.1 generate >nul 2>nul
    if errorlevel 1 (
        call npx prisma generate >nul 2>nul
    )
)

REM Créer le fichier .env si nécessaire
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
)

cd ..
echo ✅ Configuration terminee
echo.
pause
echo.

echo ETAPE 6/6: Test de la nouvelle version
echo =======================================
echo.

REM Démarrage selon le type de package
if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo Demarrage du backend OPTIMISE...
    echo   - Demarrage ultra-rapide
    echo   - Prisma pre-genere
    echo.
    cd backend
    start /min cmd /c "node src/server.js"
    cd ..
    
    echo Attente du demarrage (7 secondes)...
    timeout /t 7 /nobreak >nul
) else (
    echo Demarrage du backend ULTIMATE...
    echo   - Gestion automatique Prisma
    echo   - Scripts auto-reparateurs
    echo.
    cd backend
    if exist "start-backend.bat" (
        start /min cmd /c "start-backend.bat"
    ) else (
        start /min cmd /c "npm start"
    )
    cd ..
    
    echo Attente du demarrage (12 secondes)...
    timeout /t 12 /nobreak >nul
)

echo Test de connectivite...
curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Backend ne repond pas encore
    echo   Attente supplementaire...
    timeout /t 5 /nobreak >nul
    curl -s http://localhost:8080/health >nul 2>nul
    if errorlevel 1 (
        echo ⚠️ Backend encore en initialisation
        echo   Cela peut prendre quelques secondes de plus
    ) else (
        echo ✅ Backend fonctionne!
    )
) else (
    echo ✅ Backend fonctionne!
)

echo.
echo Demarrage de l'application...
start "" "app\logesco_v2.exe"

REM Attendre un peu avant de fermer le backend de test
timeout /t 3 /nobreak >nul
taskkill /f /im node.exe >nul 2>nul

echo.
echo ========================================
echo   MIGRATION TERMINEE
echo ========================================
echo.
echo 📦 Type de package: %PACKAGE_TYPE%
if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo    - Demarrage ultra-rapide ^(7-9 secondes^)
    echo    - Prisma pre-genere
    echo    - Optimise pour la production
) else (
    echo    - Compatible tous environnements
    echo    - Gestion automatique des versions
    echo    - Scripts auto-reparateurs
)
echo.
echo 📊 DONNEES PRESERVEES:
if defined USER_COUNT (
    echo    Utilisateurs: %USER_COUNT%
    echo    Produits: %PRODUCT_COUNT%
    echo    Ventes: %SALES_COUNT%
)
echo.
echo 📁 SAUVEGARDES:
echo    Original: %BACKUP_DIR%\
echo    Ancien backend: backend_ancien\
echo    Ancienne app: app_ancien\
echo.
echo 🚀 PROCHAINES ETAPES:
echo 1. Testez la nouvelle version
echo 2. Verifiez que toutes les donnees sont presentes
echo 3. Si tout fonctionne: supprimez les sauvegardes
echo 4. Si probleme: restaurez avec backend_ancien
echo.
if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo 🎯 DEMARRAGE RAPIDE:
    echo    Utilisez: DEMARRER-LOGESCO.bat
    echo    Temps de demarrage: 7-9 secondes
) else (
    echo 🎯 DEMARRAGE:
    echo    Utilisez: DEMARRER-LOGESCO-ULTIMATE.bat
    echo    Temps de demarrage: 15-20 secondes
)
echo.
echo 🔑 CONNEXION:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
pause