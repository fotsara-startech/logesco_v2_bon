@echo off
title LOGESCO - Diagnostic Migration Donnees
color 0E
echo ========================================
echo   DIAGNOSTIC MIGRATION DONNEES
echo   Identification du probleme
echo ========================================
echo.

echo Ce script diagnostique pourquoi vos donnees
echo ne sont pas recuperees apres migration.
echo.
pause
echo.

echo [1/7] Verification de l'emplacement
echo ====================================
echo.
echo Dossier actuel: %CD%
echo.

if not exist "backend" (
    echo ❌ Dossier backend non trouve!
    echo    Vous devez executer ce script depuis le dossier d'installation LOGESCO.
    pause
    exit /b 1
)
echo ✅ Dossier backend trouve
echo.

echo [2/7] Verification de la base de donnees
echo =========================================
echo.

if not exist "backend\database\logesco.db" (
    echo ❌ Base de donnees non trouvee!
    echo    Chemin attendu: backend\database\logesco.db
    echo.
    echo    CAUSE POSSIBLE:
    echo    - Installation incomplete
    echo    - Base supprimee par erreur
    echo    - Mauvais dossier d'installation
    echo.
    pause
    exit /b 1
)

echo ✅ Base de donnees trouvee: backend\database\logesco.db
echo.

REM Vérifier la taille
for %%A in ("backend\database\logesco.db") do set DB_SIZE=%%~zA
echo Taille de la base: %DB_SIZE% octets

if %DB_SIZE% LSS 50000 (
    echo.
    echo ⚠️  PROBLEME IDENTIFIE: Base de donnees tres petite!
    echo.
    echo    Taille actuelle: %DB_SIZE% octets
    echo    Taille attendue: ^> 100,000 octets (avec donnees)
    echo.
    echo    DIAGNOSTIC:
    echo    - Base vierge (jamais utilisee)
    echo    - Base ecrasee pendant la migration
    echo    - Donnees perdues
    echo.
    echo    SOLUTION:
    echo    1. Chercher une sauvegarde: sauvegarde_migration_*\
    echo    2. Restaurer: copy sauvegarde_*\logesco_original.db backend\database\logesco.db
    echo    3. Relancer le backend
    echo.
    set "PROBLEME_TAILLE=OUI"
) else (
    echo ✅ Taille correcte (base contient probablement des donnees)
    set "PROBLEME_TAILLE=NON"
)
echo.
pause
echo.

echo [3/7] Verification avec SQLite
echo ================================
echo.

where sqlite3 >nul 2>nul
if errorlevel 1 (
    echo ⚠️  sqlite3 non installe
    echo    Impossible de compter les donnees
    echo.
    echo    Pour installer sqlite3:
    echo    1. Telecharger: https://www.sqlite.org/download.html
    echo    2. Extraire sqlite3.exe dans C:\Windows\System32\
    echo    3. Relancer ce script
    echo.
    set "SQLITE_DISPO=NON"
    pause
    goto :skip_sqlite
)

echo ✅ sqlite3 disponible
echo.
set "SQLITE_DISPO=OUI"

echo Comptage des donnees...
echo.

for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM utilisateurs;" 2^>nul') do set USER_COUNT=%%i
for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT=%%i
for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT=%%i
for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM clients;" 2^>nul') do set CLIENT_COUNT=%%i

echo Resultats:
echo ----------
echo Utilisateurs: %USER_COUNT%
echo Produits: %PRODUCT_COUNT%
echo Ventes: %SALES_COUNT%
echo Clients: %CLIENT_COUNT%
echo.

if %USER_COUNT% EQU 0 (
    echo ❌ PROBLEME CONFIRME: Aucun utilisateur!
    echo.
    echo    DIAGNOSTIC:
    echo    - Base de donnees vierge
    echo    - Donnees non restaurees apres migration
    echo    - Base ecrasee par le package
    echo.
    set "PROBLEME_DONNEES=OUI"
) else (
    echo ✅ Donnees presentes dans la base
    set "PROBLEME_DONNEES=NON"
)
echo.
pause
echo.

:skip_sqlite

echo [4/7] Verification de Prisma
echo ==============================
echo.

if not exist "backend\node_modules\.prisma\client" (
    echo ❌ Prisma Client non genere!
    echo.
    echo    CAUSE:
    echo    - Installation incomplete
    echo    - Prisma non genere apres migration
    echo.
    echo    SOLUTION:
    echo    cd backend
    echo    npx prisma generate
    echo.
    set "PROBLEME_PRISMA=OUI"
) else (
    echo ✅ Prisma Client genere
    set "PROBLEME_PRISMA=NON"
)
echo.

if exist "backend\prisma\schema.prisma" (
    echo ✅ Schema Prisma present
) else (
    echo ❌ Schema Prisma manquant!
    set "PROBLEME_PRISMA=OUI"
)
echo.
pause
echo.

echo [5/7] Verification du fichier .env
echo ===================================
echo.

if not exist "backend\.env" (
    echo ❌ Fichier .env manquant!
    echo.
    echo    SOLUTION:
    echo    Creer backend\.env avec:
    echo.
    echo    NODE_ENV=production
    echo    PORT=8080
    echo    DATABASE_URL="file:./database/logesco.db"
    echo    JWT_SECRET="logesco-jwt-secret"
    echo.
    set "PROBLEME_ENV=OUI"
) else (
    echo ✅ Fichier .env present
    echo.
    echo Contenu:
    type "backend\.env"
    echo.
    
    findstr /C:"DATABASE_URL" "backend\.env" >nul
    if errorlevel 1 (
        echo ⚠️  DATABASE_URL manquant dans .env!
        set "PROBLEME_ENV=OUI"
    ) else (
        echo ✅ DATABASE_URL configure
        set "PROBLEME_ENV=NON"
    )
)
echo.
pause
echo.

echo [6/7] Recherche de sauvegardes
echo ================================
echo.

set "BACKUP_FOUND=NON"

for /d %%D in (sauvegarde_migration_*) do (
    echo ✅ Sauvegarde trouvee: %%D
    if exist "%%D\logesco_original.db" (
        for %%A in ("%%D\logesco_original.db") do set BACKUP_SIZE=%%~zA
        echo    Taille: !BACKUP_SIZE! octets
        
        if !BACKUP_SIZE! GTR 50000 (
            echo    ✅ Sauvegarde semble valide
            set "BACKUP_FOUND=OUI"
            set "BACKUP_PATH=%%D\logesco_original.db"
        ) else (
            echo    ⚠️  Sauvegarde tres petite
        )
    )
    echo.
)

if "%BACKUP_FOUND%"=="NON" (
    echo ⚠️  Aucune sauvegarde valide trouvee
    echo.
    
    if exist "backend_ancien\database\logesco.db" (
        echo ✅ Ancien backend trouve: backend_ancien\
        for %%A in ("backend_ancien\database\logesco.db") do set OLD_SIZE=%%~zA
        echo    Taille: !OLD_SIZE! octets
        
        if !OLD_SIZE! GTR 50000 (
            echo    ✅ Ancien backend semble contenir des donnees
            set "BACKUP_FOUND=OUI"
            set "BACKUP_PATH=backend_ancien\database\logesco.db"
        )
    )
)
echo.
pause
echo.

echo [7/7] Test de connexion backend
echo =================================
echo.

echo Tentative de demarrage du backend...
cd backend
start "LOGESCO Backend Test" /MIN node src/server.js
cd ..

echo Attente demarrage (10 secondes)...
timeout /t 10 /nobreak >nul

curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ❌ Backend ne repond pas
    echo.
    echo    CAUSES POSSIBLES:
    echo    - Port 8080 deja utilise
    echo    - Erreur au demarrage
    echo    - Probleme de configuration
    echo.
    set "PROBLEME_BACKEND=OUI"
) else (
    echo ✅ Backend fonctionne
    set "PROBLEME_BACKEND=NON"
)

taskkill /f /im node.exe >nul 2>nul
echo.
pause
echo.

echo ========================================
echo   RAPPORT DE DIAGNOSTIC
echo ========================================
echo.

echo PROBLEMES IDENTIFIES:
echo ---------------------
if "%PROBLEME_TAILLE%"=="OUI" echo ❌ Base de donnees trop petite
if "%PROBLEME_DONNEES%"=="OUI" echo ❌ Aucune donnee dans la base
if "%PROBLEME_PRISMA%"=="OUI" echo ❌ Probleme Prisma
if "%PROBLEME_ENV%"=="OUI" echo ❌ Probleme fichier .env
if "%PROBLEME_BACKEND%"=="OUI" echo ❌ Backend ne demarre pas

if "%PROBLEME_TAILLE%"=="NON" if "%PROBLEME_DONNEES%"=="NON" if "%PROBLEME_PRISMA%"=="NON" if "%PROBLEME_ENV%"=="NON" if "%PROBLEME_BACKEND%"=="NON" (
    echo ✅ Aucun probleme majeur detecte
    echo.
    echo    Si vous rencontrez quand meme des problemes:
    echo    - Verifier les logs: backend\logs\
    echo    - Tester la connexion dans l'application
    echo    - Verifier les permissions utilisateur
)
echo.

if "%BACKUP_FOUND%"=="OUI" (
    echo SAUVEGARDE DISPONIBLE:
    echo ----------------------
    echo ✅ Sauvegarde trouvee: %BACKUP_PATH%
    echo.
    echo RESTAURATION POSSIBLE:
    echo    copy "%BACKUP_PATH%" backend\database\logesco.db
    echo    cd backend
    echo    npx prisma db push --accept-data-loss
    echo    cd ..
    echo.
)

echo SOLUTIONS RECOMMANDEES:
echo -----------------------

if "%PROBLEME_DONNEES%"=="OUI" (
    echo.
    echo 1. RESTAURER LES DONNEES:
    echo    ----------------------
    if "%BACKUP_FOUND%"=="OUI" (
        echo    a. Arreter le backend: taskkill /f /im node.exe
        echo    b. Restaurer: copy "%BACKUP_PATH%" backend\database\logesco.db
        echo    c. Synchroniser: cd backend ^& npx prisma db push --accept-data-loss
        echo    d. Redemarrer: node src/server.js
    ) else (
        echo    ⚠️  Aucune sauvegarde trouvee!
        echo    - Chercher manuellement des fichiers .db
        echo    - Verifier les sauvegardes externes
        echo    - Contacter le support si donnees critiques
    )
)

if "%PROBLEME_PRISMA%"=="OUI" (
    echo.
    echo 2. REGENERER PRISMA:
    echo    -----------------
    echo    cd backend
    echo    npx prisma generate
    echo    npx prisma db push --accept-data-loss
    echo    cd ..
)

if "%PROBLEME_ENV%"=="OUI" (
    echo.
    echo 3. RECREER LE FICHIER .ENV:
    echo    ------------------------
    echo    Creer backend\.env avec le contenu minimal
)

echo.
echo 4. UTILISER LE SCRIPT DE MIGRATION CORRIGE:
echo    -----------------------------------------
echo    migration-guidee-FIXE.bat
echo.
echo    Ce script:
echo    - Supprime la base vierge du package
echo    - Restaure correctement vos donnees
echo    - Synchronise Prisma automatiquement
echo    - Verifie que les donnees sont presentes
echo.

echo ========================================
echo   FIN DU DIAGNOSTIC
echo ========================================
echo.
echo Pour plus d'aide, consultez:
echo SOLUTION_PROBLEME_MIGRATION_DONNEES.md
echo.
pause
