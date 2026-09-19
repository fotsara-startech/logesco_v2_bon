@echo off
REM ========================================
REM TUER TOUS LES NODE.JS ET RELANCER
REM ========================================

echo =========================================
echo NETTOYAGE PROCESSUS NODE.JS - LOGESCO
echo =========================================
echo.

echo [1] Arret de TOUS les processus Node.js...
taskkill /F /IM node.exe >nul 2>&1

echo    Attente 3 secondes pour nettoyage complet...
timeout /t 3 /nobreak >nul

echo    [OK] Tous les processus Node.js arretes
echo.

echo [2] Verification port 8080...
netstat -ano | findstr :8080 >nul 2>&1
if errorlevel 1 (
    echo    [OK] Port 8080 libre
) else (
    echo    [WARN] Port 8080 encore occupe, nouveau nettoyage...
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8080') do (
        taskkill /F /PID %%a >nul 2>&1
    )
    timeout /t 2 /nobreak >nul
)
echo.

echo [3] Verification finale...
netstat -ano | findstr :8080 >nul 2>&1
if errorlevel 1 (
    echo    [OK] Port 8080 definitvement libre
) else (
    echo    [ERREUR] Impossible de liberer le port 8080
    echo    Un autre programme utilise ce port.
    echo.
    echo    Processus utilisant le port 8080 :
    netstat -ano | findstr :8080
    echo.
    pause
    exit /b 1
)
echo.

echo =========================================
echo NETTOYAGE TERMINE !
echo =========================================
echo.
echo Vous pouvez maintenant relancer LOGESCO.
echo Le backend demarrera proprement sur le port 8080.
echo.
echo ETAPES SUIVANTES :
echo   1. Fermez cette fenetre
echo   2. Lancez LOGESCO normalement
echo   3. Attendez 15-30 secondes
echo   4. L'ecran de connexion devrait s'afficher
echo.
pause
