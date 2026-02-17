@echo off
title LOGESCO - Demarrage Rapide
echo ========================================
echo   LOGESCO v2 - Demarrage RAPIDE
echo   Backend optimise + Application
echo ========================================
echo.

REM Verification Node.js
where node >nul 2>nul
if errorlevel 1 (
    echo ERREUR: Node.js non installe!
    echo Telechargez: https://nodejs.org/
    pause
    exit /b 1
)

echo [1/2] Demarrage backend en arriere-plan...
cd backend
start "LOGESCO Backend" /MIN cmd /c start-backend-production.bat
cd ..

echo       Attente initialisation (5 secondes)...
timeout /t 5 /nobreak >nul

echo [2/2] Demarrage application...
start "" "logesco_v2\build\windows\x64\runner\Release\logesco_v2.exe"

echo.
echo ========================================
echo   LOGESCO demarre!
echo ========================================
echo.
echo Backend: http://localhost:8080
echo Connexion: admin / admin123
echo.
echo Cette fenetre peut etre fermee.
echo.
timeout /t 3 >nul
exit
