@echo off
title LOGESCO - Synchronisation Forcee Prisma
color 0B
echo ========================================
echo   SYNCHRONISATION FORCEE PRISMA
echo   Resolution probleme lecture donnees
echo ========================================
echo.

echo Ce script force la synchronisation entre
echo votre base de donnees et le schema Prisma.
echo.
echo SYMPTOME:
echo - Donnees presentes dans la BD (verifie avec sqlite)
echo - Mais l'application ne les affiche pas
echo.
echo CAUSE:
echo - Schema Prisma non synchronise avec la BD
echo.
pause
echo.

echo [1/5] Verification de la base de donnees
echo =========================================
echo.

if not exist "backend\database\logesco.db" (
    echo ❌ Base de donnees non trouvee!
    echo    Chemin: backend\database\logesco.db
    pause
    exit /b 1
)

for %%A in ("backend\database\logesco.db") do set DB_SIZE=%%~zA
echo ✅ Base de donnees trouvee
echo    Taille: %DB_SIZE% octets
echo.

if %DB_SIZE% LSS 50000 (
    echo ⚠️  ATTENTION: Base tres petite!
    echo    Cela peut indiquer une base vierge.
    pause
)

REM Compter les données
where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Verification des donnees...
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM utilisateurs;" 2^>nul') do set USER_COUNT=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT=%%i
    
    echo.
    echo Donnees dans la base:
    echo - Utilisateurs: %USER_COUNT%
    echo - Produits: %PRODUCT_COUNT%
    echo - Ventes: %SALES_COUNT%
    echo.
    
    if %USER_COUNT% EQU 0 (
        echo ❌ PROBLEME: Aucun utilisateur!
        echo    La base semble vide.
        pause
        exit /b 1
    ) else (
        echo ✅ Donnees presentes dans la base
    )
)
echo.
pause
echo.

echo [2/5] Arret des processus
echo ==========================
echo.
taskkill /f /im logesco_v2.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo ✅ Processus arretes
echo.

echo [3/5] Sauvegarde de securite
echo =============================
echo.

set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

if not exist "sauvegardes_sync" mkdir "sauvegardes_sync"
copy "backend\database\logesco.db" "sauvegardes_sync\logesco_avant_sync_%TIMESTAMP%.db" >nul
echo ✅ Sauvegarde creee: sauvegardes_sync\logesco_avant_sync_%TIMESTAMP%.db
echo.
pause
echo.

echo [4/5] Synchronisation FORCEE Prisma
echo ====================================
echo.

cd backend

REM Vérifier que Prisma est installé
if not exist "node_modules\.prisma" (
    echo ⚠️  Prisma Client non trouve, installation...
    call npm install >nul 2>nul
)

echo Etape 1: Suppression du client Prisma existant...
if exist "node_modules\.prisma\client" (
    rmdir /s /q "node_modules\.prisma\client" 2>nul
    echo ✅ Client Prisma supprime
) else (
    echo ℹ️  Pas de client Prisma a supprimer
)
echo.

echo Etape 2: Regeneration COMPLETE du client Prisma...
call npx prisma generate --force
if errorlevel 1 (
    echo ❌ Erreur generation Prisma
    cd ..
    pause
    exit /b 1
)
echo ✅ Client Prisma regenere
echo.

echo Etape 3: Introspection de la base de donnees...
echo (Cela permet a Prisma de "voir" la structure reelle)
call npx prisma db pull --force
if errorlevel 1 (
    echo ⚠️  Avertissement lors de l'introspection
    echo    Cela peut etre normal si le schema est deja correct
) else (
    echo ✅ Introspection reussie
)
echo.

echo Etape 4: Synchronisation du schema avec la base...
echo (Force Prisma a aligner le schema avec la BD)
call npx prisma db push --accept-data-loss --skip-generate
if errorlevel 1 (
    echo ⚠️  Avertissement lors de la synchronisation
    echo    Tentative avec force-reset...
    echo.
    echo ⚠️  ATTENTION: Cette operation peut modifier la structure!
    set /p CONFIRM="Continuer avec force-reset? (O/N): "
    if /i "!CONFIRM!"=="O" (
        call npx prisma db push --force-reset --accept-data-loss
        if errorlevel 1 (
            echo ❌ Echec de la synchronisation
            cd ..
            pause
            exit /b 1
        )
    ) else (
        echo Operation annulee
        cd ..
        pause
        exit /b 1
    )
) else (
    echo ✅ Schema synchronise
)
echo.

echo Etape 5: Regeneration finale du client...
call npx prisma generate
if errorlevel 1 (
    echo ❌ Erreur generation finale
    cd ..
    pause
    exit /b 1
)
echo ✅ Client Prisma final genere
echo.

cd ..
pause
echo.

echo [5/5] Verification et test
echo ===========================
echo.

REM Vérifier les données APRÈS synchronisation
where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Verification des donnees apres synchronisation...
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM utilisateurs;" 2^>nul') do set USER_COUNT_AFTER=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT_AFTER=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT_AFTER=%%i
    
    echo.
    echo Donnees apres synchronisation:
    echo - Utilisateurs: %USER_COUNT_AFTER%
    echo - Produits: %PRODUCT_COUNT_AFTER%
    echo - Ventes: %SALES_COUNT_AFTER%
    echo.
    
    if defined USER_COUNT (
        if %USER_COUNT_AFTER% EQU %USER_COUNT% (
            echo ✅ DONNEES PRESERVEES!
        ) else (
            echo ⚠️  ATTENTION: Difference dans les donnees!
            echo    Avant: %USER_COUNT% utilisateurs
            echo    Apres: %USER_COUNT_AFTER% utilisateurs
        )
    )
)
echo.

echo Test du backend...
cd backend
start "LOGESCO Backend Test" /MIN node src/server.js
cd ..

echo Attente demarrage (10 secondes)...
timeout /t 10 /nobreak >nul

curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ⚠️  Backend ne repond pas
    echo    Attente supplementaire...
    timeout /t 5 /nobreak >nul
    curl -s http://localhost:8080/health >nul 2>nul
    if errorlevel 1 (
        echo ⚠️  Backend encore en initialisation
        echo    Verifier les logs: backend\logs\
    ) else (
        echo ✅ Backend fonctionne!
    )
) else (
    echo ✅ Backend fonctionne!
)

echo.
echo Test API - Recuperation utilisateurs...
curl -s http://localhost:8080/api/users >nul 2>nul
if errorlevel 1 (
    echo ⚠️  API ne repond pas
) else (
    echo ✅ API fonctionne!
)

taskkill /f /im node.exe >nul 2>nul
echo.

echo ========================================
echo   SYNCHRONISATION TERMINEE
echo ========================================
echo.

if defined USER_COUNT_AFTER (
    echo 📊 DONNEES VERIFIEES:
    echo    Utilisateurs: %USER_COUNT_AFTER%
    echo    Produits: %PRODUCT_COUNT_AFTER%
    echo    Ventes: %SALES_COUNT_AFTER%
    echo.
)

echo 📁 SAUVEGARDE:
echo    sauvegardes_sync\logesco_avant_sync_%TIMESTAMP%.db
echo.

echo 🚀 PROCHAINES ETAPES:
echo 1. Demarrer LOGESCO normalement
echo 2. Se connecter et verifier les donnees
echo 3. Tester quelques operations
echo.

echo 🔑 CONNEXION:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.

echo ℹ️  Si le probleme persiste:
echo    1. Verifier les logs backend: backend\logs\
echo    2. Executer: diagnostic-migration-donnees.bat
echo    3. Consulter: SOLUTION_PROBLEME_MIGRATION_DONNEES.md
echo.

echo ⚠️  IMPORTANT:
echo    Si l'application ne lit toujours pas les donnees,
echo    il peut y avoir un probleme de mapping des colonnes.
echo    Executez: verifier-schema-bd.bat
echo.
pause
