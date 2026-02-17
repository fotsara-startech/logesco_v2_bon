@echo off
title LOGESCO - Reconstruction Rapide App
echo ========================================
echo   LOGESCO - Reconstruction Rapide App
echo ========================================
echo.

echo Ce script reconstruit uniquement l'application Flutter
echo avec la configuration corrigee (port 8080).
echo.
pause
echo.

echo [1/3] Nettoyage Flutter...
cd logesco_v2
call flutter clean >nul 2>nul
echo ✅ Nettoyage termine
echo.

echo [2/3] Recuperation des dependances...
call flutter pub get
if errorlevel 1 (
    echo ❌ ERREUR: flutter pub get echoue
    cd ..
    pause
    exit /b 1
)
echo ✅ Dependances recuperees
echo.

echo [3/3] Construction Windows...
call flutter build windows --release
if errorlevel 1 (
    echo ❌ ERREUR: Build Flutter echoue
    cd ..
    pause
    exit /b 1
)
echo ✅ Application construite
echo.

cd ..
echo ========================================
echo   Reconstruction terminee avec succes!
echo ========================================
echo.
echo 📱 Application: logesco_v2\build\windows\x64\runner\Release\
echo 🌐 Configuration: Port 8080 (CORRECT)
echo.
echo Vous pouvez maintenant:
echo 1. Tester l'app directement
echo 2. Reconstruire le package complet: preparer-pour-client-ultimate.bat
echo.
pause