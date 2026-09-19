@echo off
REM ========================================
REM VERIFICATION SCRIPTS VBS/CMD
REM ========================================

echo =========================================
echo VERIFICATION SCRIPTS VBS/CMD - LOGESCO
echo =========================================
echo.

set "BACKEND_DIR=%LOCALAPPDATA%\LOGESCO\backend"

echo [1] Verification existence scripts...
echo.

if exist "%BACKEND_DIR%\_logesco_start.cmd" (
    echo [OK] _logesco_start.cmd existe
    echo.
    echo === CONTENU CMD ===
    type "%BACKEND_DIR%\_logesco_start.cmd"
    echo.
    echo === FIN CMD ===
) else (
    echo [ERREUR] _logesco_start.cmd ABSENT !
)

echo.

if exist "%BACKEND_DIR%\_logesco_start.vbs" (
    echo [OK] _logesco_start.vbs existe
    echo.
    echo === CONTENU VBS ===
    type "%BACKEND_DIR%\_logesco_start.vbs"
    echo.
    echo === FIN VBS ===
) else (
    echo [ERREUR] _logesco_start.vbs ABSENT !
)

echo.
echo =========================================

echo.
echo [2] Test direct du script VBS...
echo.

if exist "%BACKEND_DIR%\_logesco_start.vbs" (
    echo Execution du script VBS...
    wscript.exe "%BACKEND_DIR%\_logesco_start.vbs"
    
    echo Attente 15 secondes...
    timeout /t 15 /nobreak >nul
    
    echo Test connexion backend...
    curl -s http://localhost:8080/health
    if errorlevel 1 (
        echo.
        echo [ERREUR] Le script VBS ne demarre pas le backend !
        echo.
        echo Logs backend :
        if exist "%BACKEND_DIR%\logs\backend-startup.log" (
            powershell -Command "Get-Content '%BACKEND_DIR%\logs\backend-startup.log' -Tail 20"
        )
    ) else (
        echo.
        echo [OK] Le script VBS fonctionne !
    )
    
    echo.
    echo Arret du backend...
    taskkill /F /IM node.exe >nul 2>&1
) else (
    echo IMPOSSIBLE : Script VBS absent
)

echo.
echo =========================================
pause
