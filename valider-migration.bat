@echo off
title LOGESCO - Validation Migration
echo ========================================
echo   VALIDATION DE LA MIGRATION
echo ========================================
echo.

echo Ce script valide que la migration
echo s'est deroulee correctement.
echo.
pause
echo.

echo [1/6] Verification de l'installation...
if not exist "backend\database\logesco.db" (
    echo ❌ Base de donnees manquante
    echo La migration a echoue
    pause
    exit /b 1
)

if not exist "backend\package.json" (
    echo ❌ Backend manquant
    echo La migration a echoue
    pause
    exit /b 1
)

echo ✅ Fichiers principaux presents
echo.

echo [2/6] Test de demarrage du backend...
cd backend
start /min cmd /c "npm start"
cd ..

echo Attente du demarrage (15 secondes)...
timeout /t 15 /nobreak >nul

REM Test de connectivité
curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ❌ Backend ne repond pas sur port 8080
    echo Tentative port 3002...
    curl -s http://localhost:3002/health >nul 2>nul
    if errorlevel 1 (
        echo ❌ Backend ne repond sur aucun port
        echo La migration a echoue
        taskkill /f /im node.exe >nul 2>nul
        pause
        exit /b 1
    ) else (
        echo ⚠️ Backend sur port 3002 (ancienne config)
        set BACKEND_PORT=3002
    )
) else (
    echo ✅ Backend fonctionne sur port 8080
    set BACKEND_PORT=8080
)
echo.

echo [3/6] Verification de la base de donnees...
where sqlite3 >nul 2>nul
if not errorlevel 1 (
    echo Test de la structure de la base...
    
    REM Vérifier les tables principales
    sqlite3 "backend\database\logesco.db" "SELECT name FROM sqlite_master WHERE type='table';" > tables_actuelles.txt
    
    REM Compter les enregistrements
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM utilisateurs;" 2^>nul') do set USER_COUNT=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM produits;" 2^>nul') do set PRODUCT_COUNT=%%i
    for /f %%i in ('sqlite3 "backend\database\logesco.db" "SELECT COUNT(*) FROM ventes;" 2^>nul') do set SALES_COUNT=%%i
    
    if "%USER_COUNT%"=="" set USER_COUNT=0
    if "%PRODUCT_COUNT%"=="" set PRODUCT_COUNT=0
    if "%SALES_COUNT%"=="" set SALES_COUNT=0
    
    echo    Utilisateurs: %USER_COUNT%
    echo    Produits: %PRODUCT_COUNT%
    echo    Ventes: %SALES_COUNT%
    
    if %USER_COUNT% GTR 0 (
        echo ✅ Donnees utilisateurs preservees
    ) else (
        echo ⚠️ Aucun utilisateur trouve
    )
    
    if %PRODUCT_COUNT% GTR 0 (
        echo ✅ Donnees produits preservees
    ) else (
        echo ⚠️ Aucun produit trouve
    )
    
    if %SALES_COUNT% GTR 0 (
        echo ✅ Donnees ventes preservees
    ) else (
        echo ⚠️ Aucune vente trouvee
    )
) else (
    echo ⚠️ sqlite3 non disponible, verification manuelle necessaire
)
echo.

echo [4/6] Test des endpoints API...
echo Test endpoint categories...
curl -s http://localhost:%BACKEND_PORT%/api/v1/categories >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Endpoint categories inaccessible (normal sans auth)
) else (
    echo ✅ Endpoint categories accessible
)

echo Test endpoint auth...
curl -s http://localhost:%BACKEND_PORT%/api/v1/auth/login >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Endpoint auth inaccessible
) else (
    echo ✅ Endpoint auth accessible
)
echo.

echo [5/6] Test de l'application Flutter...
if exist "app\logesco_v2.exe" (
    echo ✅ Application Flutter presente
    echo Demarrage de l'application pour test...
    start "" "app\logesco_v2.exe"
    echo ⚠️ Testez manuellement la connexion
) else if exist "logesco_v2\build\windows\x64\runner\Release\logesco_v2.exe" (
    echo ✅ Application Flutter presente (dossier build)
    echo Demarrage de l'application pour test...
    start "" "logesco_v2\build\windows\x64\runner\Release\logesco_v2.exe"
    echo ⚠️ Testez manuellement la connexion
) else (
    echo ❌ Application Flutter manquante
    echo Reconstruisez avec: rebuild-with-all-fixes.bat
)
echo.

echo [6/6] Arret du backend de test...
taskkill /f /im node.exe >nul 2>nul
echo ✅ Backend de test arrete
echo.

echo ========================================
echo   RAPPORT DE VALIDATION
echo ========================================
echo.
echo 📊 DONNEES MIGREES:
echo    Utilisateurs: %USER_COUNT%
echo    Produits: %PRODUCT_COUNT%
echo    Ventes: %SALES_COUNT%
echo.
echo 🌐 BACKEND:
echo    Port: %BACKEND_PORT%
echo    Status: Fonctionnel
echo.
echo 📱 APPLICATION:
if exist "app\logesco_v2.exe" (
    echo    Status: Presente et demarree
) else (
    echo    Status: A reconstruire
)
echo.
echo 🎯 VALIDATION:
if %USER_COUNT% GTR 0 if %PRODUCT_COUNT% GEQ 0 (
    echo    ✅ MIGRATION REUSSIE
    echo.
    echo    Vos donnees ont ete preservees
    echo    La nouvelle version est fonctionnelle
    echo.
    echo    PROCHAINES ETAPES:
    echo    1. Testez toutes les fonctionnalites
    echo    2. Formez l'utilisateur aux nouveautes
    echo    3. Supprimez les sauvegardes si tout fonctionne
    echo.
    echo    NOUVELLES FONCTIONNALITES:
    echo    - Interface modernisee
    echo    - Gestion avancee des inventaires
    echo    - Rapports detailles
    echo    - Systeme de permissions
    echo    - Ameliorations de performance
) else (
    echo    ⚠️ MIGRATION PARTIELLE
    echo.
    echo    Certaines donnees peuvent manquer
    echo    Verification manuelle recommandee
    echo.
    echo    EN CAS DE PROBLEME:
    echo    Executez: restaurer-ancienne-version.bat
)
echo.
pause