@echo off
REM ========================================
REM DEMARRAGE MANUEL BACKEND - LOGESCO
REM Solution temporaire pour MODE CLIENT
REM ========================================

echo =========================================
echo DEMARRAGE MANUEL BACKEND - LOGESCO
echo =========================================
echo.

set "BACKEND_DIR=%LOCALAPPDATA%\LOGESCO\backend"

echo Ce script demarre le backend manuellement.
echo Utilisez-le si votre application est en MODE CLIENT par erreur.
echo.

echo [1] Verification installation backend...
if not exist "%BACKEND_DIR%\src\server.js" (
    echo [ERREUR] Backend introuvable dans :
    echo %BACKEND_DIR%
    echo.
    pause
    exit /b 1
)
echo    [OK] Backend trouve
echo.

echo [2] Nettoyage processus existants...
taskkill /F /IM node.exe >nul 2>&1
timeout /t 2 /nobreak >nul
echo    [OK] Nettoyage termine
echo.

echo [3] Configuration variables d'environnement...
cd /d "%BACKEND_DIR%"

set "NODE_EXE=%BACKEND_DIR%\node.exe"
if not exist "%NODE_EXE%" set "NODE_EXE=node"

set "PORT=8080"
set "NODE_ENV=production"
set "LOGESCO_DATA_DIR=%BACKEND_DIR%"
set "DB_PATH=%BACKEND_DIR%\database\logesco.db"
set "DB_PATH_FIXED=%DB_PATH:\=/%"
set "DATABASE_URL=file:%DB_PATH_FIXED%"

echo    Port: %PORT%
echo    Node: %NODE_EXE%
echo    Database: %DB_PATH_FIXED%
echo.

echo [4] Demarrage du backend...
echo.
echo ============================================================================
echo IMPORTANT : Cette fenetre doit rester OUVERTE pendant l'utilisation de
echo             LOGESCO. Si vous la fermez, le backend s'arretera.
echo ============================================================================
echo.
echo Backend en cours de demarrage...
echo Attendez "Serveur en ecoute" puis lancez LOGESCO dans une autre fenetre.
echo.
echo ============================================================================
echo.

REM Demarrer le backend (cette commande bloque, le script reste ouvert)
"%NODE_EXE%" src\server.js

REM Cette ligne ne sera jamais atteinte tant que node.exe tourne
echo.
echo Backend arrete.
pause
