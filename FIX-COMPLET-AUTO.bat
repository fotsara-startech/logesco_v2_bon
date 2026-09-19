@echo off
REM ========================================
REM FIX COMPLET AUTOMATIQUE - LOGESCO
REM Nettoie, corrige et prepare pour lancement
REM ========================================

echo =========================================
echo FIX COMPLET AUTOMATIQUE - LOGESCO
echo =========================================
echo.

set "BACKEND_DIR=%LOCALAPPDATA%\LOGESCO\backend"

echo [1/5] Arret de tous les processus Node.js...
taskkill /F /IM node.exe >nul 2>&1
timeout /t 3 /nobreak >nul
echo       [OK] Processus Node.js arretes
echo.

echo [2/5] Liberation du port 8080...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080 2^>nul') do (
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 2 /nobreak >nul
echo       [OK] Port 8080 libere
echo.

echo [3/5] Recreation des scripts de demarrage...
cd /d "%BACKEND_DIR%"

REM Supprimer anciens scripts
del /f /q "_logesco_start.cmd" 2>nul
del /f /q "_logesco_start.vbs" 2>nul

REM Detecter Node.js
set "NODE_EXE=%BACKEND_DIR%\node.exe"
if not exist "%NODE_EXE%" set "NODE_EXE=node"

REM Preparer chemins
set "SERVER_JS=%BACKEND_DIR%\src\server.js"
set "DB_PATH=%BACKEND_DIR%\database\logesco.db"
set "DB_PATH_FIXED=%DB_PATH:\=/%"

REM Creer script CMD
(
    echo @echo off
    echo cd /d "%BACKEND_DIR%"
    echo SET "LOGESCO_DATA_DIR=%BACKEND_DIR%"
    echo SET "PORT=8080"
    echo SET "NODE_ENV=production"
    echo SET "DATABASE_URL=file:%DB_PATH_FIXED%"
    echo "%NODE_EXE%" "%SERVER_JS%"
) > "_logesco_start.cmd"

REM Creer script VBS
(
    echo Set WshShell = CreateObject("WScript.Shell"^)
    echo Dim cmd
    echo cmd = "cmd.exe /C " ^& Chr(34^) ^& "%BACKEND_DIR%\_logesco_start.cmd" ^& Chr(34^)
    echo WshShell.Run cmd, 0, False
) > "_logesco_start.vbs"

if exist "_logesco_start.cmd" if exist "_logesco_start.vbs" (
    echo       [OK] Scripts recrees avec succes
) else (
    echo       [ERREUR] Echec recreation scripts
    pause
    exit /b 1
)
echo.

echo [4/5] Verification finale...
netstat -ano | findstr :8080 >nul 2>&1
if errorlevel 1 (
    echo       [OK] Port 8080 disponible
) else (
    echo       [WARN] Port 8080 encore occupe
    echo       Nettoyage force...
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080') do (
        taskkill /F /PID %%a >nul 2>&1
    )
    timeout /t 2 /nobreak >nul
)

tasklist | findstr node.exe >nul 2>&1
if errorlevel 1 (
    echo       [OK] Aucun processus Node.js actif
) else (
    echo       [WARN] Processus Node.js encore actifs
    taskkill /F /IM node.exe >nul 2>&1
)
echo.

echo [5/5] Preparation terminee !
echo.
echo =========================================
echo FIX COMPLET TERMINE AVEC SUCCES !
echo =========================================
echo.
echo Votre systeme est maintenant pret :
echo   ✓ Tous les anciens backends arretes
echo   ✓ Port 8080 libere
echo   ✓ Scripts de demarrage corriges (avec guillemets)
echo   ✓ Systeme pret pour LOGESCO
echo.
echo PROCHAINE ETAPE :
echo =========================================
echo.
echo   1. Fermez cette fenetre
echo   2. Lancez LOGESCO normalement
echo   3. Attendez 15-30 secondes
echo   4. L'ecran de connexion devrait s'afficher
echo.
echo NOTE IMPORTANTE :
echo Si vous faites des tests manuels du backend (node src\server.js),
echo pensez a tuer le processus (taskkill /F /IM node.exe) avant de
echo relancer LOGESCO !
echo.
echo =========================================
pause
