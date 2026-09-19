@echo off
REM ========================================
REM FORCE RECREATION SCRIPTS VBS/CMD
REM Recree les scripts avec les bons chemins
REM ========================================

echo =========================================
echo FORCE RECREATION SCRIPTS - LOGESCO
echo =========================================
echo.

set "BACKEND_DIR=%LOCALAPPDATA%\LOGESCO\backend"

echo Backend Dir: %BACKEND_DIR%
echo.

cd /d "%BACKEND_DIR%"

echo [1] Suppression anciens scripts...
if exist "_logesco_start.cmd" del /f /q "_logesco_start.cmd"
if exist "_logesco_start.vbs" del /f /q "_logesco_start.vbs"
echo    [OK] Anciens scripts supprimes
echo.

echo [2] Detection Node.js...
set "NODE_EXE=%BACKEND_DIR%\node.exe"
if not exist "%NODE_EXE%" (
    echo    Node.js portable absent, utilisation systeme
    set "NODE_EXE=node"
) else (
    echo    Node.js portable: %NODE_EXE%
)
echo.

echo [3] Preparation chemins...
set "SERVER_JS=%BACKEND_DIR%\src\server.js"
set "DB_PATH=%BACKEND_DIR%\database\logesco.db"
set "DB_PATH_FIXED=%DB_PATH:\=/%"

echo    Server: %SERVER_JS%
echo    Database: %DB_PATH_FIXED%
echo.

echo [4] Creation script CMD...
(
    echo @echo off
    echo cd /d "%BACKEND_DIR%"
    echo SET "LOGESCO_DATA_DIR=%BACKEND_DIR%"
    echo SET "PORT=8080"
    echo SET "NODE_ENV=production"
    echo SET "DATABASE_URL=file:%DB_PATH_FIXED%"
    echo "%NODE_EXE%" "%SERVER_JS%"
) > "_logesco_start.cmd"

if exist "_logesco_start.cmd" (
    echo    [OK] Script CMD cree
    echo.
    echo    === CONTENU ===
    type "_logesco_start.cmd"
    echo    === FIN ===
) else (
    echo    [ERREUR] Echec creation CMD
    pause
    exit /b 1
)
echo.

echo [5] Creation script VBS...
(
    echo Set WshShell = CreateObject("WScript.Shell"^)
    echo Dim cmd
    echo cmd = "cmd.exe /C " ^& Chr(34^) ^& "%BACKEND_DIR%\_logesco_start.cmd" ^& Chr(34^)
    echo WshShell.Run cmd, 0, False
) > "_logesco_start.vbs"

if exist "_logesco_start.vbs" (
    echo    [OK] Script VBS cree
    echo.
    echo    === CONTENU ===
    type "_logesco_start.vbs"
    echo    === FIN ===
) else (
    echo    [ERREUR] Echec creation VBS
    pause
    exit /b 1
)
echo.

echo [6] Test immediat du script VBS...
echo    Arret de TOUS les processus Node.js existants...
taskkill /F /IM node.exe >nul 2>&1
timeout /t 3 /nobreak >nul

echo    Verification port 8080 libre...
netstat -ano | findstr :8080 >nul 2>&1
if not errorlevel 1 (
    echo    [WARN] Port 8080 occupe, liberation forcee...
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080') do (
        taskkill /F /PID %%a >nul 2>&1
    )
    timeout /t 2 /nobreak >nul
)

echo    Demarrage backend via VBS...
wscript.exe "_logesco_start.vbs"

echo    Attente 15 secondes...
timeout /t 15 /nobreak >nul

echo    Test connexion...
curl -s http://localhost:8080/health >nul 2>&1
if errorlevel 1 (
    echo    [ERREUR] Backend ne repond pas !
    echo.
    echo    Verification processus Node.js...
    tasklist | findstr node.exe
    echo.
    echo    Verification port 8080...
    netstat -ano | findstr :8080
    echo.
    echo    Derniers logs :
    if exist "logs\backend-startup.log" (
        powershell -Command "Get-Content 'logs\backend-startup.log' -Tail 30"
    )
    echo.
    taskkill /F /IM node.exe >nul 2>&1
    pause
    exit /b 1
)

echo    [OK] Backend repond correctement !
echo.

echo [7] Arret backend de test...
taskkill /F /IM node.exe >nul 2>&1
echo    [OK] Backend arrete
echo.

echo =========================================
echo SCRIPTS RECREES ET TESTES AVEC SUCCES !
echo =========================================
echo.
echo Les scripts ont ete recrees dans :
echo    %BACKEND_DIR%\_logesco_start.cmd
echo    %BACKEND_DIR%\_logesco_start.vbs
echo.
echo IMPORTANT : Fermez completement LOGESCO et relancez-le.
echo Le backend devrait maintenant demarrer automatiquement.
echo.
pause
