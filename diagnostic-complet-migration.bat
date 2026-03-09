@echo off
setlocal enabledelayedexpansion
title Diagnostic Complet Migration
color 0E
echo ========================================
echo   DIAGNOSTIC COMPLET MIGRATION
echo ========================================
echo.

echo Ce script effectue un diagnostic complet
echo pour identifier les problemes de migration.
echo.
pause
echo.

echo [1/7] VERIFICATION EMPLACEMENT
echo ================================
echo.
echo Dossier actuel: %CD%
echo.

if not exist "backend" (
    echo ❌ Dossier backend non trouve!
    echo    Vous n'etes pas dans un dossier d'installation LOGESCO.
    echo.
    pause
    exit /b 1
)

echo ✅ Dossier backend existe
echo.

echo [2/7] RECHERCHE BASE DE DONNEES
echo =================================
echo.

set "DB_FOUND=0"
set "DB_PATH="
set "DB_SIZE=0"

REM Recherche dans tous les emplacements
if exist "backend\database\logesco.db" (
    set "DB_PATH=backend\database\logesco.db"
    set "DB_FOUND=1"
    for %%A in ("backend\database\logesco.db") do set DB_SIZE=%%~zA
    echo ✅ Trouvee: backend\database\logesco.db
    echo    Taille: !DB_SIZE! octets
    goto :db_found
)

if exist "backend\logesco.db" (
    set "DB_PATH=backend\logesco.db"
    set "DB_FOUND=1"
    for %%A in ("backend\logesco.db") do set DB_SIZE=%%~zA
    echo ✅ Trouvee: backend\logesco.db
    echo    Taille: !DB_SIZE! octets
    goto :db_found
)

if exist "backend\prisma\logesco.db" (
    set "DB_PATH=backend\prisma\logesco.db"
    set "DB_FOUND=1"
    for %%A in ("backend\prisma\logesco.db") do set DB_SIZE=%%~zA
    echo ✅ Trouvee: backend\prisma\logesco.db
    echo    Taille: !DB_SIZE! octets
    goto :db_found
)

if exist "backend\prisma\database\logesco.db" (
    set "DB_PATH=backend\prisma\database\logesco.db"
    set "DB_FOUND=1"
    for %%A in ("backend\prisma\database\logesco.db") do set DB_SIZE=%%~zA
    echo ✅ Trouvee: backend\prisma\database\logesco.db
    echo    Taille: !DB_SIZE! octets
    goto :db_found
)

echo Recherche approfondie...
for /f "delims=" %%i in ('dir /s /b logesco.db 2^>nul') do (
    set "DB_PATH=%%i"
    set "DB_FOUND=1"
    for %%A in ("%%i") do set DB_SIZE=%%~zA
    echo ✅ Trouvee: %%i
    echo    Taille: !DB_SIZE! octets
    goto :db_found
)

echo ❌ Base de donnees NON TROUVEE!
set "DB_FOUND=0"

:db_found
echo.

echo [3/7] ANALYSE CONTENU BASE
echo ============================
echo.

if "%DB_FOUND%"=="1" (
    where sqlite3 >nul 2>nul
    if not errorlevel 1 (
        echo Comptage des donnees...
        for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM utilisateurs;" 2^>nul') do set USER_COUNT=%%i
        for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT=%%i
        for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM clients;" 2^>nul') do set CLIENT_COUNT=%%i
        for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT=%%i
        
        echo Contenu de la base:
        echo   Utilisateurs: !USER_COUNT!
        echo   Produits: !PRODUCT_COUNT!
        echo   Clients: !CLIENT_COUNT!
        echo   Ventes: !SALES_COUNT!
        echo.
        
        if "!PRODUCT_COUNT!"=="0" (
            echo ⚠️ BASE VIERGE DETECTEE!
            echo    Cette base ne contient aucune donnee.
        ) else (
            echo ✅ Base contient des donnees
        )
    ) else (
        echo ⚠️ sqlite3 non disponible
        echo    Impossible de compter les donnees
        echo.
        if %DB_SIZE% LSS 100000 (
            echo ⚠️ Taille suspecte: %DB_SIZE% octets
            echo    Une base avec donnees fait generalement plus de 100 KB
        )
    )
) else (
    echo ❌ Pas de base a analyser
)
echo.

echo [4/7] VERIFICATION CONFIGURATION
echo ==================================
echo.

if exist "backend\.env" (
    echo ✅ Fichier .env existe
    echo.
    echo DATABASE_URL:
    type "backend\.env" | findstr DATABASE_URL
    echo.
    
    REM Vérifier cohérence
    type "backend\.env" | findstr DATABASE_URL | findstr "database/logesco.db" >nul
    if errorlevel 1 (
        echo ⚠️ DATABASE_URL ne pointe pas vers database/logesco.db
        if "%DB_FOUND%"=="1" (
            echo    Base trouvee dans: %DB_PATH%
            echo    Mais .env pointe ailleurs!
            echo    → INCOHERENCE DETECTEE
        )
    ) else (
        echo ✅ DATABASE_URL pointe vers database/logesco.db
        if "%DB_FOUND%"=="1" (
            echo %DB_PATH% | findstr "database\\logesco.db" >nul
            if errorlevel 1 (
                echo ⚠️ Mais base trouvee ailleurs: %DB_PATH%
                echo    → INCOHERENCE DETECTEE
            ) else (
                echo ✅ Coherent avec emplacement reel
            )
        )
    )
) else (
    echo ❌ Fichier .env non trouve
)
echo.

echo [5/7] VERIFICATION PRISMA
echo ==========================
echo.

if exist "backend\prisma\schema.prisma" (
    echo ✅ schema.prisma existe
    echo.
    echo Datasource url:
    findstr /C:"url" "backend\prisma\schema.prisma" | findstr /V "///"
    echo.
) else (
    echo ❌ schema.prisma non trouve
)

if exist "backend\node_modules\.prisma\client" (
    echo ✅ Client Prisma genere
) else (
    echo ⚠️ Client Prisma non genere
    echo    → Prisma doit etre regenere
)
echo.

echo [6/7] TEST BACKEND
echo ===================
echo.

echo Verification si backend est deja en cours...
netstat -ano | findstr ":8080" >nul 2>nul
if not errorlevel 1 (
    echo ✅ Backend deja en cours sur port 8080
    echo.
    echo Test API...
    curl -s http://localhost:8080/health >nul 2>nul
    if not errorlevel 1 (
        echo ✅ Backend repond
    ) else (
        echo ⚠️ Backend ne repond pas
    )
) else (
    echo ⚠️ Backend non demarre
    echo.
    echo Tentative de demarrage pour test...
    cd backend
    start /min cmd /c "node src/server.js"
    cd ..
    
    echo Attente 10 secondes...
    timeout /t 10 /nobreak >nul
    
    curl -s http://localhost:8080/health >nul 2>nul
    if not errorlevel 1 (
        echo ✅ Backend demarre et repond
        
        REM Arrêter le backend de test
        taskkill /f /im node.exe >nul 2>nul
    ) else (
        echo ❌ Backend ne demarre pas
        echo    Verifier les logs dans backend\
        
        REM Arrêter le backend de test
        taskkill /f /im node.exe >nul 2>nul
    )
)
echo.

echo [7/7] VERIFICATION PACKAGE MIGRATION
echo ======================================
echo.

set "PACKAGE_FOUND=0"

if exist "Package-Mise-A-Jour\LOGESCO-Client-Optimise" (
    echo ✅ Package Optimise trouve
    set "PACKAGE_FOUND=1"
    
    REM Vérifier si le package contient une base vierge
    if exist "Package-Mise-A-Jour\LOGESCO-Client-Optimise\backend\database\logesco.db" (
        for %%A in ("Package-Mise-A-Jour\LOGESCO-Client-Optimise\backend\database\logesco.db") do set PKG_DB_SIZE=%%~zA
        echo    Contient base de donnees: !PKG_DB_SIZE! octets
        
        if !PKG_DB_SIZE! LSS 100000 (
            echo    ⚠️ BASE VIERGE dans le package!
            echo    → Sera supprimee lors de la migration
        )
    )
) else if exist "LOGESCO-Client-Optimise" (
    echo ✅ Package Optimise trouve
    set "PACKAGE_FOUND=1"
    
    if exist "LOGESCO-Client-Optimise\backend\database\logesco.db" (
        for %%A in ("LOGESCO-Client-Optimise\backend\database\logesco.db") do set PKG_DB_SIZE=%%~zA
        echo    Contient base de donnees: !PKG_DB_SIZE! octets
        
        if !PKG_DB_SIZE! LSS 100000 (
            echo    ⚠️ BASE VIERGE dans le package!
            echo    → Sera supprimee lors de la migration
        )
    )
) else (
    echo ⚠️ Package de mise a jour non trouve
    echo    Migration impossible sans package
)
echo.

echo ========================================
echo   RESUME DIAGNOSTIC
echo ========================================
echo.

echo BASE DE DONNEES:
if "%DB_FOUND%"=="1" (
    echo   ✅ Trouvee: %DB_PATH%
    echo   Taille: %DB_SIZE% octets
    if defined PRODUCT_COUNT (
        echo   Produits: %PRODUCT_COUNT%
        echo   Clients: %CLIENT_COUNT%
        echo   Ventes: %SALES_COUNT%
    )
) else (
    echo   ❌ Non trouvee
)
echo.

echo CONFIGURATION:
if exist "backend\.env" (
    echo   ✅ .env existe
) else (
    echo   ❌ .env manquant
)
if exist "backend\prisma\schema.prisma" (
    echo   ✅ schema.prisma existe
) else (
    echo   ❌ schema.prisma manquant
)
if exist "backend\node_modules\.prisma\client" (
    echo   ✅ Client Prisma genere
) else (
    echo   ⚠️ Client Prisma a regenerer
)
echo.

echo PACKAGE MIGRATION:
if "%PACKAGE_FOUND%"=="1" (
    echo   ✅ Package disponible
) else (
    echo   ❌ Package manquant
)
echo.

echo ========================================
echo   RECOMMANDATIONS
echo ========================================
echo.

if "%DB_FOUND%"=="0" (
    echo ❌ PROBLEME CRITIQUE: Base de donnees non trouvee
    echo.
    echo ACTIONS:
    echo 1. Verifier que vous etes dans le bon dossier
    echo 2. Chercher logesco.db manuellement
    echo 3. Verifier si une sauvegarde existe
    echo.
) else (
    if defined PRODUCT_COUNT (
        if "%PRODUCT_COUNT%"=="0" (
            echo ⚠️ Base de donnees vide
            echo.
            echo ACTIONS:
            echo 1. Restaurer depuis une sauvegarde
            echo 2. Ou c'est une nouvelle installation
            echo.
        ) else (
            echo ✅ Base de donnees valide avec donnees
            echo.
            if "%PACKAGE_FOUND%"=="1" (
                echo PRET POUR MIGRATION!
                echo.
                echo Utilisez: migration-guidee-corrigee.bat
            ) else (
                echo ⚠️ Package de migration manquant
                echo    Copiez le package avant de migrer
            )
        )
    ) else (
        echo ⚠️ Impossible de verifier le contenu
        echo.
        if %DB_SIZE% LSS 100000 (
            echo Base suspecte (trop petite)
            echo Verifier si c'est une base vierge
        ) else (
            echo Taille correcte, probablement valide
        )
    )
)
echo.

echo ========================================
echo   SCRIPTS DISPONIBLES
echo ========================================
echo.
echo - trouver-base-donnees.bat
echo   → Recherche detaillee de la base
echo.
echo - verifier-config-database.bat
echo   → Verification configuration
echo.
echo - migration-guidee-corrigee.bat
echo   → Migration intelligente
echo.
echo - SOLUTION_PROBLEME_BASE_DONNEES.md
echo   → Guide complet
echo.
pause
