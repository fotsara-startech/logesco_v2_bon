@echo off
chcp 65001 > nul
cls

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║  MIGRATION CLIENT: Ajout colonnes NUI et RCCM               ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo [INFO] Ce script ajoute les colonnes NUI et RCCM
echo [INFO] au backend embarqué chez le client
echo.
echo ─────────────────────────────────────────────────────────────────
echo.

REM Définir le chemin du backend embarqué
set "BACKEND_EMB=%LOCALAPPDATA%\LOGESCO\backend"
set "DB_PATH=%BACKEND_EMB%\database\logesco.db"

echo [1/5] Vérification du backend embarqué...
if not exist "%BACKEND_EMB%" (
    echo [❌] Backend embarqué non trouvé: %BACKEND_EMB%
    echo [INFO] L'application n'a peut-être pas encore été exécutée
    echo.
    pause
    exit /b 1
)
echo [✓] Backend embarqué trouvé
echo.

echo [2/5] Vérification de la base de données...
if not exist "%DB_PATH%" (
    echo [❌] Base de données non trouvée: %DB_PATH%
    echo.
    pause
    exit /b 1
)
echo [✓] Base de données trouvée
echo.

echo [3/5] Copie du script de migration...
if not exist "backend\fix-clients-nui-rccm-sqlite.js" (
    echo [❌] Script de migration non trouvé dans backend\
    echo.
    pause
    exit /b 1
)

copy /Y "backend\fix-clients-nui-rccm-sqlite.js" "%BACKEND_EMB%\" >nul
if %ERRORLEVEL% NEQ 0 (
    echo [❌] Erreur lors de la copie du script
    echo.
    pause
    exit /b 1
)
echo [✓] Script copié vers le backend embarqué
echo.

echo [4/5] Arrêt de l'application et du backend...
taskkill /F /IM logesco_v2.exe 2>nul
taskkill /F /IM node.exe 2>nul
echo [✓] Processus arrêtés
timeout /t 2 /nobreak >nul
echo.

echo [5/5] Exécution de la migration...
echo.
echo ════════════════════════════════════════════════════════════════
echo.

REM Exécuter le script dans le répertoire du backend embarqué
cd /d "%BACKEND_EMB%"

REM Trouver Node.js
set "NODE_EXE=%BACKEND_EMB%\node.exe"
if not exist "%NODE_EXE%" (
    set "NODE_EXE=node"
)

"%NODE_EXE%" fix-clients-nui-rccm-sqlite.js

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ════════════════════════════════════════════════════════════════
    echo.
    echo [❌] La migration a échoué
    echo [INFO] Vérifiez les messages d'erreur ci-dessus
    echo.
    pause
    exit /b 1
)

echo.
echo ════════════════════════════════════════════════════════════════
echo.

REM Nettoyer le script temporaire
del /Q fix-clients-nui-rccm-sqlite.js 2>nul

REM Retourner au répertoire initial
cd /d "%~dp0"

echo ════════════════════════════════════════════════════════════════
echo   ✅ MIGRATION RÉUSSIE CHEZ LE CLIENT
echo ════════════════════════════════════════════════════════════════
echo.
echo [RÉSULTAT]
echo.
echo ✓ Colonnes NUI et RCCM ajoutées à la table clients
echo ✓ Backend embarqué: %BACKEND_EMB%
echo ✓ Base de données: logesco.db
echo.
echo [PROCHAINE ÉTAPE]
echo.
echo Redémarrez l'application LOGESCO
echo Les champs NUI et RCCM seront maintenant disponibles
echo dans la fiche client
echo.
echo ════════════════════════════════════════════════════════════════
echo.
pause
