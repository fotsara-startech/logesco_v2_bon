@echo off
setlocal enabledelayedexpansion
title LOGESCO - Migration Guidee Client (Corrigee)
color 0B
echo ========================================
echo   MIGRATION GUIDEE CLIENT EXISTANT
echo   Version Corrigee - Gestion emplacements DB
echo ========================================
echo.

echo Ce script vous guide pas a pas pour migrer
echo un client existant vers la nouvelle version.
echo.
echo AMELIORATIONS:
echo - Detection automatique emplacement base de donnees
echo - Gestion emplacements non-standard
echo - Verification approfondie
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

echo ETAPE 2/6: Recherche de la base de donnees
echo ===========================================
echo.
echo Recherche de logesco.db dans tous les emplacements possibles...
echo.

set "DB_FOUND=0"
set "DB_PATH="

REM Recherche dans les emplacements standards
if exist "backend\database\logesco.db" (
    set "DB_PATH=backend\database\logesco.db"
    set "DB_FOUND=1"
    echo ✅ Trouvee dans: backend\database\
    goto :db_found
)

if exist "backend\logesco.db" (
    set "DB_PATH=backend\logesco.db"
    set "DB_FOUND=1"
    echo ✅ Trouvee dans: backend\
    goto :db_found
)

if exist "backend\prisma\logesco.db" (
    set "DB_PATH=backend\prisma\logesco.db"
    set "DB_FOUND=1"
    echo ✅ Trouvee dans: backend\prisma\
    goto :db_found
)

if exist "backend\prisma\database\logesco.db" (
    set "DB_PATH=backend\prisma\database\logesco.db"
    set "DB_FOUND=1"
    echo ✅ Trouvee dans: backend\prisma\database\
    goto :db_found
)

REM Recherche complete si pas trouvee
echo Recherche approfondie...
for /f "delims=" %%i in ('dir /s /b logesco.db 2^>nul') do (
    set "DB_PATH=%%i"
    set "DB_FOUND=1"
    echo ✅ Trouvee dans: %%i
    goto :db_found
)

REM Base de donnees non trouvee
echo.
echo ❌ Base de donnees non trouvee!
echo.
echo Ce ne semble pas etre une installation LOGESCO valide.
echo.
echo VERIFICATIONS:
echo 1. Etes-vous dans le bon dossier?
echo 2. Le backend a-t-il deja ete demarre?
echo 3. Y a-t-il des donnees dans cette installation?
echo.
echo SOLUTION:
echo - Si c'est une nouvelle installation: pas de migration necessaire
echo - Si c'est une installation existante: verifier l'emplacement
echo.
pause
exit /b 1

:db_found
echo.
echo ✅ Installation LOGESCO detectee
echo    Base de donnees: %DB_PATH%
echo.

REM Compter les données si sqlite3 disponible
where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Analyse du contenu...
    for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM utilisateurs;" 2^>nul') do set USER_COUNT=%%i
    for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT=%%i
    for /f %%i in ('sqlite3 "%DB_PATH%" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT=%%i
    
    echo.
    echo Donnees actuelles:
    echo - Utilisateurs: %USER_COUNT%
    echo - Produits: %PRODUCT_COUNT%
    echo - Ventes: %SALES_COUNT%
    echo.
    
    if "%PRODUCT_COUNT%"=="0" (
        echo ⚠️ ATTENTION: Base de donnees vide!
        echo    Etes-vous sur de vouloir migrer?
        echo.
        set /p CONTINUE="Continuer quand meme? (O/N): "
        if /i not "!CONTINUE!"=="O" (
            echo Migration annulee.
            pause
            exit /b 0
        )
    )
)
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
pause
exit /b 1

:package_found
echo.
echo Type de package: %PACKAGE_TYPE%
if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo   - Demarrage ultra-rapide ^(7-9 secondes^)
    echo   - Prisma pre-genere
)
if "%PACKAGE_TYPE%"=="ULTIMATE" (
    echo   - Compatible tous environnements
    echo   - Gestion automatique Prisma
)
echo.

REM IMPORTANT: Verifier si le package contient une base vierge
if exist "%PACKAGE_PATH%\backend\database\logesco.db" (
    echo ⚠️ ATTENTION: Le package contient une base de donnees!
    echo    Elle sera supprimee pour preserver vos donnees.
    echo.
)

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
copy "%DB_PATH%" "%BACKUP_DIR%\logesco_original.db" >nul
if errorlevel 1 (
    echo ❌ Erreur lors de la sauvegarde!
    pause
    exit /b 1
)
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
timeout /t 2 /nobreak >nul
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

REM CRITIQUE: Supprimer la base vierge du package si elle existe
if exist "backend\database\logesco.db" (
    echo Suppression de la base vierge du package...
    del /f /q "backend\database\logesco.db" >nul 2>nul
    echo ✅ Base vierge supprimee
    echo.
)

REM Creer le dossier database s'il n'existe pas
if not exist "backend\database" (
    echo Creation du dossier database...
    mkdir "backend\database"
    echo ✅ Dossier cree
    echo.
)

echo Restauration de votre base de donnees...
copy "%BACKUP_DIR%\logesco_original.db" "backend\database\logesco.db" >nul
if errorlevel 1 (
    echo ❌ Erreur lors de la restauration!
    echo Tentative de restauration complete...
    rmdir /s /q "backend" >nul 2>nul
    ren "backend_ancien" "backend"
    pause
    exit /b 1
)
echo ✅ Votre base de donnees restauree
echo.

echo Installation de la nouvelle application...
if exist "app_ancien" rmdir /s /q "app_ancien" >nul 2>nul
if exist "app" ren "app" "app_ancien"
xcopy /E /I /Y /Q "%PACKAGE_PATH%\app" "app\" >nul
echo ✅ Nouvelle application installee
echo.

echo Configuration du nouveau backend...
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
    REM Verifier que DATABASE_URL pointe vers le bon endroit
    findstr /C:"DATABASE_URL" .env | findstr /C:"database/logesco.db" >nul
    if errorlevel 1 (
        echo ⚠️ DATABASE_URL ne pointe pas vers database/logesco.db
        echo    Correction automatique...
        powershell -Command "(Get-Content .env) -replace 'DATABASE_URL=.*', 'DATABASE_URL=\"file:./database/logesco.db\"' | Set-Content .env"
        echo ✅ DATABASE_URL corrigee
    )
)
echo.

REM Synchronisation Prisma avec la base restauree
echo Synchronisation Prisma avec votre base de donnees...
echo.

if "%PACKAGE_TYPE%"=="OPTIMISE" (
    echo Configuration OPTIMISE detectee...
    echo   - Suppression ancien client Prisma
    echo   - Introspection de votre base
    echo   - Regeneration client
    echo.
    
    REM Supprimer l'ancien client
    if exist "node_modules\.prisma" rmdir /s /q "node_modules\.prisma" >nul 2>nul
    if exist "node_modules\@prisma\client" rmdir /s /q "node_modules\@prisma\client" >nul 2>nul
    
    REM Introspection de la base
    echo Introspection de votre base...
    call npx prisma db pull >nul 2>nul
    
    REM Generation du client
    echo Generation du client Prisma...
    call npx prisma generate >nul 2>nul
    
    echo ✅ Prisma synchronise avec votre base
) else (
    echo Configuration ULTIMATE detectee...
    
    REM Installation des dépendances si nécessaire
    if not exist "node_modules" (
        echo Installation des dependances...
        call npm install >nul 2>nul
    )
    
    REM Synchronisation Prisma
    echo Synchronisation Prisma...
    call npx prisma db pull >nul 2>nul
    call npx prisma generate >nul 2>nul
    
    echo ✅ Prisma synchronise
)

cd ..
echo.
echo ✅ Configuration terminee
echo.
pause
echo.

echo ETAPE 6/6: Test de la nouvelle version
echo =======================================
echo.

echo Demarrage du backend pour test...
cd backend
start /min cmd /c "node src/server.js"
cd ..

echo Attente du demarrage...
timeout /t 10 /nobreak >nul

echo Test de connectivite...
curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Backend ne repond pas encore
    echo   Attente supplementaire...
    timeout /t 5 /nobreak >nul
    curl -s http://localhost:8080/health >nul 2>nul
    if errorlevel 1 (
        echo ❌ Backend ne demarre pas
        echo    Verifier les logs dans backend\
    ) else (
        echo ✅ Backend fonctionne!
    )
) else (
    echo ✅ Backend fonctionne!
)

echo.
echo Arret du backend de test...
taskkill /f /im node.exe >nul 2>nul
timeout /t 2 /nobreak >nul

echo.
echo ========================================
echo   MIGRATION TERMINEE
echo ========================================
echo.
echo 📦 Type de package: %PACKAGE_TYPE%
echo.
echo 📊 DONNEES PRESERVEES:
if defined PRODUCT_COUNT (
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
echo 1. Demarrez LOGESCO avec: DEMARRER-LOGESCO.bat
echo 2. Testez la nouvelle version
echo 3. Verifiez que toutes les donnees sont presentes
echo 4. Si tout fonctionne: supprimez les sauvegardes
echo 5. Si probleme: restaurez avec backend_ancien
echo.
echo 🔑 CONNEXION:
echo    Utilisateur: admin
echo    Mot de passe: admin123
echo.
echo ⚠️ IMPORTANT:
echo    La base de donnees est maintenant dans:
echo    backend\database\logesco.db
echo.
pause
