@echo off
REM ========================================
REM DEBUG PROBLEME DE PORT - LOGESCO
REM ========================================

echo =========================================
echo DEBUG PROBLEME DE PORT - LOGESCO
echo =========================================
echo.

set "BACKEND_DIR=%LOCALAPPDATA%\LOGESCO\backend"

echo [1] Verification scripts generes...
echo.

if exist "%BACKEND_DIR%\_logesco_start.cmd" (
    echo === CONTENU _logesco_start.cmd ===
    type "%BACKEND_DIR%\_logesco_start.cmd"
    echo.
    echo === FIN CMD ===
) else (
    echo [ERREUR] _logesco_start.cmd absent !
)

echo.

if exist "%BACKEND_DIR%\_logesco_start.vbs" (
    echo === CONTENU _logesco_start.vbs ===
    type "%BACKEND_DIR%\_logesco_start.vbs"
    echo.
    echo === FIN VBS ===
) else (
    echo [ERREUR] _logesco_start.vbs absent !
)

echo.
echo [2] Verification fichier .env...
echo.

if exist "%BACKEND_DIR%\.env" (
    echo === CONTENU .env ===
    type "%BACKEND_DIR%\.env"
    echo.
    echo === FIN .env ===
) else (
    echo [ERREUR] .env absent !
)

echo.
echo [3] Test demarrage manuel avec port explicite...
echo.

cd /d "%BACKEND_DIR%"

echo Arret processus existants...
taskkill /F /IM node.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo Demarrage backend avec PORT=8080 explicite...
set "PORT=8080"
set "NODE_ENV=production"
set "LOGESCO_DATA_DIR=%BACKEND_DIR%"
set "DATABASE_URL=file:%BACKEND_DIR:\=/%/database/logesco.db"

start "LOGESCO Backend Test" /MIN node src\server.js

echo Attente 15 secondes...
timeout /t 15 /nobreak >nul

echo.
echo [4] Test connexion sur port 8080...
curl -s http://localhost:8080/health
if errorlevel 1 (
    echo.
    echo [ERREUR] Backend ne repond pas sur port 8080 !
) else (
    echo.
    echo [OK] Backend repond sur port 8080 !
)

echo.
echo [5] Verification processus actifs...
echo.
netstat -ano | findstr LISTENING | findstr node.exe

echo.
echo [6] Verification tous les ports utilises...
echo.
netstat -ano | findstr node.exe

echo.
echo [7] Derniers logs backend...
echo.
if exist "logs\backend-startup.log" (
    powershell -Command "Get-Content 'logs\backend-startup.log' -Tail 40"
)

echo.
echo =========================================
echo.
echo ANALYSE :
echo Si le backend repond sur port 8080, le probleme vient de Flutter.
echo Si le backend ne repond pas, le probleme vient du backend.
echo Si vous voyez un port different de 8080, c'est le probleme.
echo.

taskkill /F /IM node.exe >nul 2>&1

pause
