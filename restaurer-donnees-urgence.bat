@echo off
title LOGESCO - Restauration Urgence Donnees
color 0C
echo ========================================
echo   RESTAURATION URGENCE DES DONNEES
echo ========================================
echo.

echo Ce script restaure vos donnees en cas d'urgence
echo apres une migration qui a echoue.
echo.
echo ⚠️  ATTENTION: Ce script va:
echo    1. Arreter tous les processus LOGESCO
echo    2. Restaurer la base de donnees depuis une sauvegarde
echo    3. Synchroniser Prisma
echo    4. Redemarrer le backend
echo.
pause
echo.

echo [1/6] Arret des processus
echo ==========================
echo.
taskkill /f /im logesco_v2.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
timeout /t 2 /nobreak >nul
echo ✅ Processus arretes
echo.

echo [2/6] Recherche de sauvegardes
echo ===============================
echo.

set "BACKUP_FOUND=0"
set "BACKUP_PATH="
set "BACKUP_SIZE=0"

REM Chercher la sauvegarde la plus récente
for /f "delims=" %%D in ('dir /b /ad /o-d sauvegarde_migration_* 2^>nul') do (
    if exist "%%D\logesco_original.db" (
        for %%A in ("%%D\logesco_original.db") do set BACKUP_SIZE=%%~zA
        
        if !BACKUP_SIZE! GTR 50000 (
            set "BACKUP_PATH=%%D\logesco_original.db"
            set "BACKUP_FOUND=1"
            echo ✅ Sauvegarde trouvee: %%D
            echo    Taille: !BACKUP_SIZE! octets
            echo    Date: %%~tD
            goto :backup_found
        )
    )
)

REM Si pas de sauvegarde migration, chercher backend_ancien
if exist "backend_ancien\database\logesco.db" (
    for %%A in ("backend_ancien\database\logesco.db") do set BACKUP_SIZE=%%~zA
    
    if !BACKUP_SIZE! GTR 50000 (
        set "BACKUP_PATH=backend_ancien\database\logesco.db"
        set "BACKUP_FOUND=1"
        echo ✅ Ancien backend trouve: backend_ancien\
        echo    Taille: !BACKUP_SIZE! octets
        goto :backup_found
    )
)

echo ❌ Aucune sauvegarde valide trouvee!
echo.
echo Emplacements verifies:
echo - sauvegarde_migration_*\logesco_original.db
echo - backend_ancien\database\logesco.db
echo.
echo SOLUTIONS:
echo 1. Chercher manuellement des fichiers .db
echo 2. Verifier les sauvegardes externes
echo 3. Verifier la corbeille Windows
echo.
pause
exit /b 1

:backup_found
echo.

REM Compter les données dans la sauvegarde
where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Verification de la sauvegarde...
    for /f %%i in ('sqlite3 "%BACKUP_PATH%" "SELECT COUNT(*) FROM utilisateurs;" 2^>nul') do set USER_COUNT=%%i
    for /f %%i in ('sqlite3 "%BACKUP_PATH%" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT=%%i
    for /f %%i in ('sqlite3 "%BACKUP_PATH%" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT=%%i
    
    echo.
    echo Donnees dans la sauvegarde:
    echo - Utilisateurs: %USER_COUNT%
    echo - Produits: %PRODUCT_COUNT%
    echo - Ventes: %SALES_COUNT%
    echo.
    
    if %USER_COUNT% EQU 0 (
        echo ⚠️  ATTENTION: Aucun utilisateur dans la sauvegarde!
        echo    Cette sauvegarde semble vide.
        echo.
        set /p CONTINUE="Continuer quand meme? (O/N): "
        if /i not "!CONTINUE!"=="O" exit /b 0
    )
)
echo.
pause
echo.

echo [3/6] Sauvegarde de la base actuelle
echo =====================================
echo.

if exist "backend\database\logesco.db" (
    set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
    set TIMESTAMP=!TIMESTAMP: =0!
    
    if not exist "sauvegardes_urgence" mkdir "sauvegardes_urgence"
    copy "backend\database\logesco.db" "sauvegardes_urgence\logesco_avant_restauration_!TIMESTAMP!.db" >nul
    echo ✅ Base actuelle sauvegardee dans: sauvegardes_urgence\
) else (
    echo ℹ️  Pas de base actuelle a sauvegarder
)
echo.

echo [4/6] Restauration de la base de donnees
echo =========================================
echo.

if not exist "backend\database" mkdir "backend\database"

echo Copie de la sauvegarde...
copy "%BACKUP_PATH%" "backend\database\logesco.db" >nul
if errorlevel 1 (
    echo ❌ Erreur lors de la copie!
    pause
    exit /b 1
)
echo ✅ Base de donnees restauree
echo.

REM Vérifier la taille
for %%A in ("backend\database\logesco.db") do set NEW_SIZE=%%~zA
echo Taille de la base restauree: %NEW_SIZE% octets

if %NEW_SIZE% LSS 50000 (
    echo ⚠️  ATTENTION: Base tres petite!
    pause
)
echo.

echo [5/6] Synchronisation Prisma
echo =============================
echo.

cd backend

REM Vérifier que Prisma est installé
if not exist "node_modules\.prisma\client" (
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
)

echo Synchronisation du schema avec la base restauree...
call npx prisma db push --accept-data-loss
if errorlevel 1 (
    echo ⚠️  Avertissement lors de la synchronisation
    echo    Cela peut etre normal si le schema est deja a jour
) else (
    echo ✅ Schema synchronise
)

cd ..
echo.
pause
echo.

echo [6/6] Verification et test
echo ===========================
echo.

REM Vérifier les données APRÈS restauration
where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Verification des donnees restaurees...
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM utilisateurs;" 2^>nul') do set USER_COUNT_AFTER=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT_AFTER=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT_AFTER=%%i
    
    echo.
    echo Donnees apres restauration:
    echo - Utilisateurs: %USER_COUNT_AFTER%
    echo - Produits: %PRODUCT_COUNT_AFTER%
    echo - Ventes: %SALES_COUNT_AFTER%
    echo.
    
    if %USER_COUNT_AFTER% GTR 0 (
        echo ✅ DONNEES RESTAUREES AVEC SUCCES!
    ) else (
        echo ❌ PROBLEME: Aucune donnee apres restauration!
        echo.
        echo Causes possibles:
        echo - Sauvegarde corrompue
        echo - Probleme de synchronisation Prisma
        echo - Base de donnees vide
        echo.
        pause
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
    echo    Verifier les logs: backend\logs\
) else (
    echo ✅ Backend fonctionne!
)

taskkill /f /im node.exe >nul 2>nul
echo.

echo ========================================
echo   RESTAURATION TERMINEE
echo ========================================
echo.

if "%BACKUP_FOUND%"=="1" (
    echo ✅ Base de donnees restauree depuis:
    echo    %BACKUP_PATH%
    echo.
)

if defined USER_COUNT_AFTER (
    echo 📊 DONNEES RESTAUREES:
    echo    Utilisateurs: %USER_COUNT_AFTER%
    echo    Produits: %PRODUCT_COUNT_AFTER%
    echo    Ventes: %SALES_COUNT_AFTER%
    echo.
)

echo 📁 SAUVEGARDES:
echo    Sauvegarde utilisee: %BACKUP_PATH%
if exist "sauvegardes_urgence" (
    echo    Base avant restauration: sauvegardes_urgence\
)
echo.

echo 🚀 PROCHAINES ETAPES:
echo 1. Demarrer LOGESCO normalement
echo 2. Se connecter et verifier les donnees
echo 3. Tester quelques operations
echo 4. Si tout fonctionne, supprimer les anciennes sauvegardes
echo.

echo 🔑 CONNEXION:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.

echo ℹ️  Si le probleme persiste:
echo    1. Executer: diagnostic-migration-donnees.bat
echo    2. Consulter: SOLUTION_PROBLEME_MIGRATION_DONNEES.md
echo    3. Utiliser: migration-guidee-FIXE.bat pour une migration propre
echo.
pause
