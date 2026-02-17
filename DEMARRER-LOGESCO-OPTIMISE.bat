@echo off
title LOGESCO v2 - Demarrage OPTIMISE
color 0A

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║         LOGESCO v2 - Demarrage OPTIMISE               ║
echo ║         Demarrage ultra-rapide en arriere-plan        ║
echo ╚════════════════════════════════════════════════════════╝
echo.

REM Verification Node.js rapide
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ ERREUR: Node.js non installe!
    echo.
    echo Telechargez Node.js 18+: https://nodejs.org/
    echo.
    pause
    exit /b 1
)

echo ✅ Node.js detecte
echo.

REM Verification backend
if not exist "backend\src\server.js" (
    echo ❌ ERREUR: Backend manquant!
    pause
    exit /b 1
)

REM Verification application
if not exist "logesco_v2\build\windows\x64\runner\Release\logesco_v2.exe" (
    echo ❌ ERREUR: Application manquante!
    echo.
    echo Executez d'abord: flutter build windows --release
    echo.
    pause
    exit /b 1
)

echo [1/2] Demarrage backend en arriere-plan...
echo       (Prisma pre-genere, demarrage immediat!)
echo.

cd backend

REM Creer database si necessaire
if not exist "database" mkdir "database"

REM Demarrage silencieux en arriere-plan
start "LOGESCO Backend" /MIN node src/server.js

cd ..

echo       ✅ Backend demarre en arriere-plan
echo       Attente initialisation (4 secondes)...
echo.

timeout /t 4 /nobreak >nul

echo [2/2] Demarrage application...
echo.

start "" "logesco_v2\build\windows\x64\runner\Release\logesco_v2.exe"

echo ✅ Application demarree
echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║         LOGESCO v2 est maintenant actif!              ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo 🌐 Backend: http://localhost:8080
echo 🔑 Connexion: admin / admin123
echo 📱 Interface: Application Windows
echo.
echo ℹ️  Cette fenetre peut etre fermee.
echo    Le backend tourne en arriere-plan.
echo.
echo    Pour arreter: Fermez l'application ou executez
echo    ARRETER-LOGESCO.bat
echo.

timeout /t 5 >nul
exit
