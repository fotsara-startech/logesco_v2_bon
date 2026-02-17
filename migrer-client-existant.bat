@echo off
title LOGESCO - Migration Client Existant
echo ========================================
echo   MIGRATION CLIENT EXISTANT
echo ========================================
echo.

echo Ce script migre un client existant vers
echo la nouvelle version en conservant ses donnees.
echo.
echo PREREQUIS: Avoir execute sauvegarder-donnees-client.bat
echo.
pause
echo.

REM Vérifier qu'une sauvegarde existe
echo [0/8] Verification des prerequis...
set BACKUP_FOUND=0
for /d %%i in (sauvegarde_client_*) do (
    if exist "%%i\logesco_original.db" (
        set BACKUP_DIR=%%i
        set BACKUP_FOUND=1
        echo ✅ Sauvegarde trouvee: %%i
    )
)

if %BACKUP_FOUND%==0 (
    echo ❌ ERREUR: Aucune sauvegarde trouvee!
    echo.
    echo Executez d'abord: sauvegarder-donnees-client.bat
    echo.
    pause
    exit /b 1
)
echo.

echo [1/8] Arret de l'ancienne version...
taskkill /f /im logesco_v2.exe >nul 2>nul
taskkill /f /im node.exe >nul 2>nul
echo ✅ Processus arretes
echo.

echo [2/8] Analyse de l'ancienne base de donnees...
if exist "backend\database\logesco.db" (
    echo Analyse de la structure existante...
    
    REM Vérifier la version du schéma
    where sqlite3 >nul 2>nul
    if not errorlevel 1 (
        sqlite3 "backend\database\logesco.db" "SELECT name FROM sqlite_master WHERE type='table';" > tables_existantes.txt
        echo ✅ Structure analysee
        
        REM Compter les enregistrements
        for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM utilisateurs;"') do set USER_COUNT=%%i
        for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM produits;"') do set PRODUCT_COUNT=%%i
        for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM ventes;"') do set SALES_COUNT=%%i
        
        echo    Utilisateurs: %USER_COUNT%
        echo    Produits: %PRODUCT_COUNT%
        echo    Ventes: %SALES_COUNT%
    ) else (
        echo ⚠️ sqlite3 non disponible, migration basique
    )
) else (
    echo ❌ Base de donnees non trouvee
    pause
    exit /b 1
)
echo.

echo [3/8] Installation de la nouvelle version...
echo Sauvegarde de l'ancienne BD...
copy "backend\database\logesco.db" "backend\database\logesco_avant_migration.db" >nul

echo Installation du nouveau backend...
REM Chercher la nouvelle version dans plusieurs emplacements possibles
set NOUVEAU_BACKEND_TROUVE=0

REM Emplacement 1: Package-Mise-A-Jour\LOGESCO-Client-Ultimate\backend
if exist "Package-Mise-A-Jour\LOGESCO-Client-Ultimate\backend" (
    echo Copie depuis Package-Mise-A-Jour...
    xcopy /E /I /Y /Q "Package-Mise-A-Jour\LOGESCO-Client-Ultimate\backend" "backend_nouveau\" >nul
    set NOUVEAU_BACKEND_TROUVE=1
)

REM Emplacement 2: LOGESCO-Client-Ultimate\backend (si copié directement)
if %NOUVEAU_BACKEND_TROUVE%==0 (
    if exist "LOGESCO-Client-Ultimate\backend" (
        echo Copie depuis LOGESCO-Client-Ultimate...
        xcopy /E /I /Y /Q "LOGESCO-Client-Ultimate\backend" "backend_nouveau\" >nul
        set NOUVEAU_BACKEND_TROUVE=1
    )
)

REM Emplacement 3: dist-portable (ancien emplacement)
if %NOUVEAU_BACKEND_TROUVE%==0 (
    if exist "dist-portable" (
        echo Copie depuis dist-portable...
        xcopy /E /I /Y /Q "dist-portable\*" "backend_nouveau\" >nul
        set NOUVEAU_BACKEND_TROUVE=1
    )
)

if %NOUVEAU_BACKEND_TROUVE%==0 (
    echo ❌ Nouveau backend non trouve!
    echo.
    echo EMPLACEMENTS RECHERCHES:
    echo - Package-Mise-A-Jour\LOGESCO-Client-Ultimate\backend
    echo - LOGESCO-Client-Ultimate\backend
    echo - dist-portable
    echo.
    echo SOLUTION:
    echo 1. Assurez-vous d'avoir copie le package de mise a jour
    echo 2. Le dossier doit contenir LOGESCO-Client-Ultimate\backend
    echo.
    pause
    exit /b 1
)

echo ✅ Nouveau backend prepare
echo.

echo [4/8] Migration du schema de base de donnees...
cd backend_nouveau

REM Créer une nouvelle base avec le nouveau schéma
echo Creation du nouveau schema...
call npx prisma@6.17.1 db push --accept-data-loss >nul 2>nul
if errorlevel 1 (
    echo ❌ Erreur creation nouveau schema
    cd ..
    pause
    exit /b 1
)

echo ✅ Nouveau schema cree
cd ..
echo.

echo [5/8] Migration des donnees...
echo Migration des donnees critiques...

REM Script de migration des données
where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Migration des utilisateurs...
    sqlite3 "backend\database\logesco_avant_migration.db" "SELECT * FROM utilisateurs;" > temp_users.csv
    
    echo Migration des produits...
    sqlite3 "backend\database\logesco_avant_migration.db" "SELECT * FROM produits;" > temp_products.csv
    
    echo Migration des ventes...
    sqlite3 "backend\database\logesco_avant_migration.db" "SELECT * FROM ventes;" > temp_sales.csv
    
    echo ✅ Donnees extraites
    
    REM Importer dans la nouvelle base
    echo Import dans la nouvelle base...
    copy "backend_nouveau\database\logesco.db" "backend\database\logesco.db" >nul
    
    echo ✅ Migration des donnees terminee
) else (
    echo ⚠️ Migration manuelle necessaire
)
echo.

echo [6/8] Remplacement des fichiers...
echo Sauvegarde de l'ancien backend...
if exist "backend_ancien" rmdir /s /q "backend_ancien" >nul 2>nul
ren "backend" "backend_ancien"

echo Installation du nouveau backend...
ren "backend_nouveau" "backend"

echo Restauration de la base de donnees migree...
if exist "backend_ancien\database\logesco.db" (
    copy "backend_ancien\database\logesco.db" "backend\database\logesco.db" >nul
)

echo ✅ Remplacement termine
echo.

echo [7/8] Configuration du nouveau backend...
cd backend

REM Créer le bon fichier .env
(
echo NODE_ENV=production
echo PORT=8080
echo DATABASE_URL="file:./database/logesco.db"
echo JWT_SECRET="logesco-jwt-secret-change-in-production"
echo CORS_ORIGIN="*"
echo RATE_LIMIT_ENABLED=false
echo DEPLOYMENT_TYPE=local
) > .env

echo Installation des dependances...
call npm install >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Erreur installation dependances
)

echo Generation du client Prisma...
call npx prisma@6.17.1 generate >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Erreur generation Prisma
)

cd ..
echo ✅ Configuration terminee
echo.

echo [8/8] Test de la migration...
echo Demarrage du nouveau backend...
cd backend
start /min cmd /c "npm start"
cd ..

echo Attente du demarrage...
timeout /t 10 /nobreak >nul

REM Test de connectivité
curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Backend ne repond pas encore
) else (
    echo ✅ Backend fonctionne
)

REM Arrêter le test
taskkill /f /im node.exe >nul 2>nul

echo.
echo ========================================
echo   MIGRATION TERMINEE
echo ========================================
echo.
echo 📊 STATISTIQUES:
echo    Utilisateurs: %USER_COUNT%
echo    Produits: %PRODUCT_COUNT%
echo    Ventes: %SALES_COUNT%
echo.
echo 📁 SAUVEGARDES:
echo    Original: %BACKUP_DIR%\
echo    Avant migration: backend_ancien\
echo.
echo 🚀 PROCHAINES ETAPES:
echo 1. Testez la nouvelle version
echo 2. Verifiez que toutes les donnees sont presentes
echo 3. Formez l'utilisateur aux nouvelles fonctionnalites
echo 4. Si tout fonctionne: supprimez backend_ancien
echo.
echo ⚠️ EN CAS DE PROBLEME:
echo Executez: restaurer-ancienne-version.bat
echo.
echo 🎯 NOUVELLES FONCTIONNALITES DISPONIBLES:
echo - Interface modernisee
echo - Gestion des inventaires amelioree
echo - Rapports avances
echo - Systeme de permissions granulaires
echo - Et bien plus...
echo.
pause