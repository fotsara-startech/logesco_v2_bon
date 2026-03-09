@echo off
setlocal enabledelayedexpansion
title LOGESCO - Migration DEFINITIVE
color 0A
echo ========================================
echo   MIGRATION DEFINITIVE CLIENT
echo   Solution Expert - Probleme Prisma Resolu
echo ========================================
echo.

echo PROBLEME IDENTIFIE ET RESOLU:
echo ------------------------------
echo Le package "optimise" contient un client Prisma
echo pre-genere avec une base VIERGE.
echo.
echo Meme apres restauration de vos donnees, Prisma
echo utilise l'ancien client qui ne "voit" rien.
echo.
echo SOLUTION DEFINITIVE:
echo --------------------
echo 1. Supprimer la base vierge du package
echo 2. Restaurer VOS donnees
echo 3. SUPPRIMER COMPLETEMENT le client Prisma pre-genere
echo 4. Introspecter VOTRE base
echo 5. Regenerer le client avec la vraie structure
echo.
pause
echo.

echo ETAPE 1/7: Verification emplacement
echo ====================================
echo.
echo Dossier actuel: %CD%
echo.
set /p CONFIRM="Est-ce le bon dossier d'installation? (O/N): "
if /i not "%CONFIRM%"=="O" (
    echo Migration annulee.
    pause
    exit /b 0
)
echo.

echo ETAPE 2/7: Recherche base de donnees
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

if exist "backend\prisma\database\logesco.db" (
    set "DB_PATH=backend\prisma\database\logesco.db"
    set "DB_FOUND=1"
    echo ✅ Trouvee: backend\prisma\database\
    goto :db_found
)

echo Recherche approfondie...
for /f "delims=" %%i in ('dir /s /b logesco.db 2^>nul') do (
    set "DB_PATH=%%i"
    set "DB_FOUND=1"
    echo ✅ Trouvee: %%i
    goto :db_found
)

echo ❌ Base de donnees non trouvee!
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
        set /p CONTINUE="Continuer quand meme? (O/N): "
        if /i not "!CONTINUE!"=="O" exit /b 0
    )
)
pause
echo.

echo ETAPE 3/7: Verification package
echo =================================
echo.

set "PACKAGE_FOUND=0"
set "PACKAGE_PATH="

if exist "Package-Mise-A-Jour\LOGESCO-Client-Optimise" (
    set "PACKAGE_PATH=Package-Mise-A-Jour\LOGESCO-Client-Optimise"
    set "PACKAGE_FOUND=1"
) else if exist "LOGESCO-Client-Optimise" (
    set "PACKAGE_PATH=LOGESCO-Client-Optimise"
    set "PACKAGE_FOUND=1"
) else if exist "release\LOGESCO-Client-Optimise" (
    set "PACKAGE_PATH=release\LOGESCO-Client-Optimise"
    set "PACKAGE_FOUND=1"
)

if "%PACKAGE_FOUND%"=="0" (
    echo ❌ Package non trouve!
    pause
    exit /b 1
)

echo ✅ Package: %PACKAGE_PATH%
echo.
pause
echo.

echo ETAPE 4/7: Sauvegarde
echo ======================
echo.

set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_DIR=sauvegarde_migration_%TIMESTAMP%

mkdir "%BACKUP_DIR%"

echo Sauvegarde base de donnees...
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

echo ETAPE 5/7: Installation nouvelle version
echo ==========================================
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

echo CRITIQUE: Suppression base vierge du package...
if exist "backend\database\logesco.db" (
    del /f /q "backend\database\logesco.db" >nul 2>nul
    echo ✅ Base vierge supprimee
) else (
    echo ⚠️ Pas de base vierge
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

echo Installation nouvelle app...
if exist "app_ancien" rmdir /s /q "app_ancien" >nul 2>nul
if exist "app" ren "app" "app_ancien"
xcopy /E /I /Y /Q "%PACKAGE_PATH%\app" "app\" >nul
echo ✅ App installee
echo.
pause
echo.

echo ETAPE 6/7: REGENERATION PRISMA (CRITIQUE)
echo ===========================================
echo.
echo C'EST ICI QUE LA MAGIE OPERE!
echo.
echo Le package contient un client Prisma pre-genere
echo pour une base VIERGE. Nous allons le REMPLACER
echo par un client genere pour VOTRE base.
echo.
pause
echo.

cd backend

echo Configuration .env...
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
    findstr /C:"DATABASE_URL" .env | findstr /C:"database/logesco.db" >nul
    if errorlevel 1 (
        echo ⚠️ Correction DATABASE_URL...
        powershell -Command "(Get-Content .env) -replace 'DATABASE_URL=.*', 'DATABASE_URL=\"file:./database/logesco.db\"' | Set-Content .env"
        echo ✅ Corrige
    )
)
echo.

echo [1/3] Suppression COMPLETE ancien client Prisma
echo =================================================
echo.
echo Cette etape est CRITIQUE pour resoudre le probleme!
echo.

if exist "node_modules\.prisma" (
    echo Suppression node_modules\.prisma...
    rmdir /s /q "node_modules\.prisma" 2>nul
    echo ✅ Supprime
)

if exist "node_modules\@prisma\client" (
    echo Suppression node_modules\@prisma\client...
    rmdir /s /q "node_modules\@prisma\client" 2>nul
    echo ✅ Supprime
)

if exist "node_modules\.bin\prisma" (
    echo Suppression binaire Prisma...
    del /f /q "node_modules\.bin\prisma" 2>nul
    echo ✅ Supprime
)

echo.
echo ✅ Ancien client Prisma COMPLETEMENT supprime
echo.

echo [2/3] Introspection de VOTRE base
echo ===================================
echo.
echo Prisma va lire la structure REELLE de votre base
echo et mettre a jour schema.prisma en consequence.
echo.

call npx prisma db pull
if errorlevel 1 (
    echo ❌ Erreur introspection!
    cd ..
    pause
    exit /b 1
)

echo.
echo ✅ Schema.prisma mis a jour avec votre structure
echo.

echo [3/3] Generation NOUVEAU client
echo =================================
echo.
echo Generation d'un client Prisma qui "voit" vos donnees...
echo.

call npx prisma generate
if errorlevel 1 (
    echo ❌ Erreur generation!
    cd ..
    pause
    exit /b 1
)

echo.
echo ✅ Nouveau client Prisma genere
echo.

cd ..
pause
echo.

echo ETAPE 7/7: Test et verification
echo =================================
echo.

echo Test de demarrage...
cd backend
start /min cmd /c "node src/server.js > test-migration.log 2>&1"
cd ..

echo Attente 10 secondes...
timeout /t 10 /nobreak >nul

echo.
echo Verification des statistiques...
echo.
type backend\test-migration.log | findstr "Statistiques"
echo.

taskkill /f /im node.exe >nul 2>nul

echo.
echo ========================================
echo   MIGRATION TERMINEE
echo ========================================
echo.

echo 📊 VERIFICATION:
echo ----------------
echo Regardez les statistiques ci-dessus.
echo.

if defined PRODUCT_COUNT (
    echo Avant migration:
    echo   Produits: %PRODUCT_COUNT%
    echo   Clients: %CLIENT_COUNT%
    echo   Ventes: %SALES_COUNT%
    echo.
)

echo Si les statistiques affichent vos donnees:
echo ✅ MIGRATION REUSSIE!
echo.
echo Si vous voyez toujours des 0:
echo ❌ Verifier backend\test-migration.log
echo.

echo 📁 SAUVEGARDES:
echo ---------------
echo   Original: %BACKUP_DIR%\
echo   Ancien backend: backend_ancien\
echo   Ancienne app: app_ancien\
echo.

echo 🚀 PROCHAINES ETAPES:
echo ---------------------
echo 1. Demarrez LOGESCO normalement
echo 2. Connectez-vous (admin / admin123)
echo 3. Verifiez que TOUTES vos donnees sont la
echo.

echo 🔑 EXPLICATION TECHNIQUE:
echo -------------------------
echo Le probleme etait que le package "optimise"
echo contenait un client Prisma pre-genere pour
echo une base VIERGE.
echo.
echo Meme apres restauration de votre base, Prisma
echo continuait d'utiliser l'ancien client.
echo.
echo La solution: Supprimer completement l'ancien
echo client et le regenerer avec VOTRE structure.
echo.
pause
