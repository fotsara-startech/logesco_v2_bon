@echo off
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

set PACKAGE_TROUVE=0

if exist "Package-Mise-A-Jour\LOGESCO-Client-Ultimate" (
    echo ✅ Package trouve: Package-Mise-A-Jour\LOGESCO-Client-Ultimate
    set PACKAGE_PATH=Package-Mise-A-Jour\LOGESCO-Client-Ultimate
    set PACKAGE_TROUVE=1
) else if exist "LOGESCO-Client-Ultimate" (
    echo ✅ Package trouve: LOGESCO-Client-Ultimate
    set PACKAGE_PATH=LOGESCO-Client-Ultimate
    set PACKAGE_TROUVE=1
) else if exist "release\LOGESCO-Client-Ultimate" (
    echo ✅ Package trouve: release\LOGESCO-Client-Ultimate
    set PACKAGE_PATH=release\LOGESCO-Client-Ultimate
    set PACKAGE_TROUVE=1
)

if %PACKAGE_TROUVE%==0 (
    echo ❌ Package de mise a jour non trouve!
    echo.
    echo SOLUTION:
    echo 1. Copiez le dossier LOGESCO-Client-Ultimate ici
    echo 2. Ou copiez-le dans un sous-dossier Package-Mise-A-Jour
    echo.
    echo Le package doit contenir:
    echo - backend\
    echo - app\
    echo - Scripts de demarrage
    echo.
    pause
    exit /b 1
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
if not exist ".env" (
    (
    echo NODE_ENV=production
    echo PORT=8080
    echo DATABASE_URL="file:./database/logesco.db"
    echo JWT_SECRET="logesco-jwt-secret-change-in-production"
    echo CORS_ORIGIN="*"
    echo RATE_LIMIT_ENABLED=false
    ) > .env
)

echo Installation des dependances...
call npm install >nul 2>nul

echo Generation du client Prisma...
call npx prisma@6.17.1 generate >nul 2>nul
if errorlevel 1 (
    call npx prisma generate >nul 2>nul
)

cd ..
echo ✅ Configuration terminee
echo.
pause
echo.

echo ETAPE 6/6: Test de la nouvelle version
echo =======================================
echo.
echo Demarrage du backend...
cd backend
start /min cmd /c "npm start"
cd ..

echo Attente du demarrage (10 secondes)...
timeout /t 10 /nobreak >nul

echo Test de connectivite...
curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Backend ne repond pas encore
) else (
    echo ✅ Backend fonctionne!
)

echo.
echo Demarrage de l'application...
start "" "app\logesco_v2.exe"

taskkill /f /im node.exe >nul 2>nul

echo.
echo ========================================
echo   MIGRATION TERMINEE
echo ========================================
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
echo 🎯 NOUVELLES FONCTIONNALITES:
echo - Interface modernisee
echo - Gestion avancee des inventaires
echo - Rapports detailles
echo - Systeme de permissions
echo.
pause