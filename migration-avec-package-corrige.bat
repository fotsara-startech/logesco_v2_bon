@echo off
setlocal enabledelayedexpansion
title Migration avec Package CORRIGE
color 0B
echo ========================================
echo   MIGRATION CLIENT
echo   Avec Package CORRIGE
echo ========================================
echo.

echo Ce script migre votre installation vers
echo le nouveau package CORRIGE (sans Prisma pre-genere).
echo.
pause
echo.

echo ETAPE 1/6: Verification emplacement
echo ====================================
echo.
echo Dossier actuel: %CD%
echo.
set /p CONFIRM="C'est le dossier d'installation LOGESCO? (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo Migration annulee.
    pause
    exit /b 0
)
echo.

echo ETAPE 2/6: Recherche base de donnees
echo ======================================
echo.

set "DB_FOUND=0"
set "DB_PATH="

if exist "backend\database\logesco.db" (
    set "DB_PATH=backend\database\logesco.db"
    set "DB_FOUND=1"
    echo ✅ Trouvee: backend\database\
    goto :db_found
)

if exist "backend\logesco.db" (
    set "DB_PATH=backend\logesco.db"
    set "DB_FOUND=1"
    echo ✅ Trouvee: backend\
    goto :db_found
)

if exist "backend\prisma\logesco.db" (
    set "DB_PATH=backend\prisma\logesco.db"
    set "DB_FOUND=1"
    echo ✅ Trouvee: backend\prisma\
    goto :db_found
)

echo Recherche approfondie...
for /f "delims=" %%i in ('dir /s /b logesco.db 2^>nul') do (
    set "DB_PATH=%%i"
    set "DB_FOUND=1"
    echo ✅ Trouvee: %%i
    goto :db_found
)

echo ❌ Base non trouvee!
pause
exit /b 1

:db_found
echo.
echo Base: %DB_PATH%
echo.

where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Analyse du contenu...
    for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT=%%i
    for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM clients;" 2^>nul') do set CLIENT_COUNT=%%i
    for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT=%%i
    
    echo   Produits: !PRODUCT_COUNT!
    echo   Clients: !CLIENT_COUNT!
    echo   Ventes: !SALES_COUNT!
    echo.
    
    if "!PRODUCT_COUNT!"=="0" (
        echo ⚠️ Base vide!
        set /p CONTINUE="Continuer? (O/N): "
        if /i not "!CONTINUE!"=="O" exit /b 0
    )
)
pause
echo.

echo ETAPE 3/6: Recherche package
echo ==============================
echo.

set "PACKAGE_FOUND=0"
set "PACKAGE_PATH="
set "PACKAGE_TYPE=UNKNOWN"

REM Recherche package CORRIGE (prioritaire)
if exist "Package-Mise-A-Jour\LOGESCO-Client-CORRIGE" (
    set "PACKAGE_PATH=Package-Mise-A-Jour\LOGESCO-Client-CORRIGE"
    set "PACKAGE_TYPE=CORRIGE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package CORRIGE: Package-Mise-A-Jour\LOGESCO-Client-CORRIGE
    goto :package_found
)

if exist "LOGESCO-Client-CORRIGE" (
    set "PACKAGE_PATH=LOGESCO-Client-CORRIGE"
    set "PACKAGE_TYPE=CORRIGE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package CORRIGE: LOGESCO-Client-CORRIGE
    goto :package_found
)

if exist "release\LOGESCO-Client-CORRIGE" (
    set "PACKAGE_PATH=release\LOGESCO-Client-CORRIGE"
    set "PACKAGE_TYPE=CORRIGE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package CORRIGE: release\LOGESCO-Client-CORRIGE
    goto :package_found
)

REM Recherche package OPTIMISE (ancien)
if exist "Package-Mise-A-Jour\LOGESCO-Client-Optimise" (
    set "PACKAGE_PATH=Package-Mise-A-Jour\LOGESCO-Client-Optimise"
    set "PACKAGE_TYPE=OPTIMISE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package OPTIMISE: Package-Mise-A-Jour\LOGESCO-Client-Optimise
    echo    ⚠️  Ancien package (avec Prisma pre-genere)
    goto :package_found
)

if exist "LOGESCO-Client-Optimise" (
    set "PACKAGE_PATH=LOGESCO-Client-Optimise"
    set "PACKAGE_TYPE=OPTIMISE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package OPTIMISE: LOGESCO-Client-Optimise
    echo    ⚠️  Ancien package (avec Prisma pre-genere)
    goto :package_found
)

if exist "release\LOGESCO-Client-Optimise" (
    set "PACKAGE_PATH=release\LOGESCO-Client-Optimise"
    set "PACKAGE_TYPE=OPTIMISE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package OPTIMISE: release\LOGESCO-Client-Optimise
    echo    ⚠️  Ancien package (avec Prisma pre-genere)
    goto :package_found
)

REM Recherche package ULTIMATE
if exist "Package-Mise-A-Jour\LOGESCO-Client-Ultimate" (
    set "PACKAGE_PATH=Package-Mise-A-Jour\LOGESCO-Client-Ultimate"
    set "PACKAGE_TYPE=ULTIMATE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package ULTIMATE: Package-Mise-A-Jour\LOGESCO-Client-Ultimate
    goto :package_found
)

if exist "LOGESCO-Client-Ultimate" (
    set "PACKAGE_PATH=LOGESCO-Client-Ultimate"
    set "PACKAGE_TYPE=ULTIMATE"
    set "PACKAGE_FOUND=1"
    echo ✅ Package ULTIMATE: LOGESCO-Client-Ultimate
    goto :package_found
)

echo ❌ Aucun package trouve!
echo.
echo Packages supportes:
echo - LOGESCO-Client-CORRIGE (Recommande)
echo - LOGESCO-Client-Optimise
echo - LOGESCO-Client-Ultimate
echo.
pause
exit /b 1

:package_found
echo.
echo Type: %PACKAGE_TYPE%
echo.

if "%PACKAGE_TYPE%"=="CORRIGE" (
    echo ✅ Package CORRIGE detecte
    echo    - Prisma NON pre-genere
    echo    - Sera genere avec VOTRE base
    echo    - Pas de probleme de synchronisation
)

if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo ⚠️  Package OPTIMISE detecte
    echo    - Prisma pre-genere (base vide)
    echo    - Sera supprime et regenere
    echo    - Recommande: Utilisez package CORRIGE
)

if "%PACKAGE_TYPE%"=="ULTIMATE" (
    echo ✅ Package ULTIMATE detecte
    echo    - Compatible tous environnements
)

echo.
pause
echo.

echo ETAPE 4/6: Sauvegarde
echo ======================
echo.

set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_DIR=sauvegarde_migration_%TIMESTAMP%

mkdir "%BACKUP_DIR%"

echo Sauvegarde base...
copy "%DB_PATH%" "%BACKUP_DIR%\logesco_original.db" >nul
if errorlevel 1 (
    echo ❌ Erreur sauvegarde!
    pause
    exit /b 1
)

if exist "backend\.env" copy "backend\.env" "%BACKUP_DIR%\.env_original" >nul
if exist "backend\uploads" xcopy /E /I /Y /Q "backend\uploads" "%BACKUP_DIR%\uploads" >nul 2>nul

echo ✅ Sauvegarde: %BACKUP_DIR%
echo.
pause
echo.

echo ETAPE 5/6: Installation
echo ========================
echo.

echo Arret processus...
taskkill /f /im logesco_v2.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo ✅ Arretes
echo.

echo Sauvegarde ancien backend...
if exist "backend_ancien" rmdir /s /q "backend_ancien" >nul 2>nul
ren "backend" "backend_ancien"
echo ✅ Sauvegarde
echo.

echo Installation nouveau backend...
xcopy /E /I /Y /Q "%PACKAGE_PATH%\backend" "backend\" >nul
if errorlevel 1 (
    echo ❌ Erreur copie!
    ren "backend_ancien" "backend"
    pause
    exit /b 1
)
echo ✅ Installe
echo.

if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo ⚠️  Package OPTIMISE: Suppression Prisma pre-genere...
    cd backend
    if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" 2>nul
    if exist "node_modules\@prisma\client" rmdir /s /q "node_modules\@prisma\client" 2>nul
    cd ..
    echo ✅ Prisma pre-genere supprime
    echo.
)

if "%PACKAGE_TYPE%"=="CORRIGE" (
    echo ✅ Package CORRIGE: Pas de Prisma pre-genere
    echo    (Sera genere au demarrage avec votre base)
    echo.
)

echo Suppression base vierge du package...
if exist "backend\database\logesco.db" (
    del /f /q "backend\database\logesco.db" >nul 2>nul
    echo ✅ Base vierge supprimee
) else (
    echo ✅ Pas de base vierge
)
echo.

if not exist "backend\database" mkdir "backend\database"

echo Restauration de VOTRE base...
copy "%BACKUP_DIR%\logesco_original.db" "backend\database\logesco.db" >nul
if errorlevel 1 (
    echo ❌ Erreur restauration!
    rmdir /s /q "backend" >nul 2>nul
    ren "backend_ancien" "backend"
    pause
    exit /b 1
)
echo ✅ Votre base restauree
echo.

echo Installation app...
if exist "app_ancien" rmdir /s /q "app_ancien" >nul 2>nul
if exist "app" ren "app" "app_ancien"
xcopy /E /I /Y /Q "%PACKAGE_PATH%\app" "app\" >nul
echo ✅ App installee
echo.

echo Configuration .env...
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
    echo ✅ .env cree
) else (
    echo ✅ .env existe
)
cd ..
echo.
pause
echo.

echo ETAPE 6/6: Generation Prisma (CRITIQUE)
echo ===========================================
echo.

echo IMPORTANT: Generation Prisma avec VOTRE base...
echo (Cela prend 10-15 secondes)
echo.

cd backend

REM TOUJOURS generer Prisma apres restauration de la base
REM Meme pour package CORRIGE, car on vient de copier une nouvelle base

call npx prisma generate >nul 2>nul
if errorlevel 1 (
    echo ❌ Erreur generation Prisma!
    echo.
    echo Tentative avec db pull...
    call npx prisma db pull >nul 2>nul
    call npx prisma generate >nul 2>nul
    if errorlevel 1 (
        echo ❌ Echec generation
        echo    Verifier manuellement
        cd ..
        pause
        exit /b 1
    )
)

echo ✅ Prisma genere avec votre base
cd ..
echo.

echo Test demarrage...
cd backend
start /min cmd /c "node src/server.js > test-migration.log 2>&1"
cd ..

echo Attente 10 secondes...
timeout /t 10 /nobreak >nul

echo.
echo Verification...
type backend\test-migration.log | findstr "Statistiques"
echo.

taskkill /f /im node.exe >nul 2>nul

echo.
echo ========================================
echo   MIGRATION TERMINEE
echo ========================================
echo.

echo 📦 Package utilise: %PACKAGE_TYPE%
echo.

if defined PRODUCT_COUNT (
    echo 📊 Donnees avant migration:
    echo    Produits: %PRODUCT_COUNT%
    echo    Clients: %CLIENT_COUNT%
    echo    Ventes: %SALES_COUNT%
    echo.
)

echo 📁 Sauvegardes:
echo    Original: %BACKUP_DIR%\
echo    Ancien backend: backend_ancien\
echo    Ancienne app: app_ancien\
echo.

echo 🚀 PROCHAINES ETAPES:
echo    1. Lancez: DEMARRER-LOGESCO.bat
echo    2. Connectez-vous: admin / admin123
echo    3. Verifiez vos donnees
echo.

if "%PACKAGE_TYPE%"=="CORRIGE" (
    echo ℹ️  PREMIERE UTILISATION:
    echo    Le demarrage prendra 15-20 secondes
    echo    (generation Prisma avec votre base)
    echo.
    echo    Utilisations suivantes: 7-9 secondes
    echo.
)

if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo ⚠️  ATTENTION:
    echo    Ancien package OPTIMISE utilise
    echo    Prisma pre-genere a ete supprime
    echo    Recommande: Utilisez package CORRIGE
    echo.
)

pause
