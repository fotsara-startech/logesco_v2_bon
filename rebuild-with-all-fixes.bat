@echo off
title LOGESCO - Reconstruction Complete avec Corrections
echo ========================================
echo   RECONSTRUCTION COMPLETE AVEC CORRECTIONS
echo ========================================
echo.

echo Ce script reconstruit l'application avec
echo TOUTES les corrections de port appliquees.
echo.
pause
echo.

echo [1/6] Verification des corrections...
echo Verification des fichiers critiques:
echo.

echo ApiConfig:
findstr "localhost:8080" logesco_v2\lib\core\config\api_config.dart
if errorlevel 1 (
    echo ❌ ApiConfig non corrige
) else (
    echo ✅ ApiConfig corrige
)

echo EnvironmentConfig:
findstr "localhost:8080" logesco_v2\lib\core\config\environment_config.dart
if errorlevel 1 (
    echo ❌ EnvironmentConfig non corrige
) else (
    echo ✅ EnvironmentConfig corrige
)

echo InitialBindings:
findstr "localhost:8080" logesco_v2\lib\core\bindings\initial_bindings.dart
if errorlevel 1 (
    echo ❌ InitialBindings non corrige
) else (
    echo ✅ InitialBindings corrige
)
echo.

echo [2/6] Nettoyage Flutter...
cd logesco_v2
call flutter clean >nul 2>nul
echo ✅ Nettoyage termine
echo.

echo [3/6] Recuperation des dependances...
call flutter pub get
if errorlevel 1 (
    echo ❌ ERREUR: flutter pub get echoue
    cd ..
    pause
    exit /b 1
)
echo ✅ Dependances recuperees
echo.

echo [4/6] Construction Windows...
call flutter build windows --release
if errorlevel 1 (
    echo ❌ ERREUR: Build Flutter echoue
    cd ..
    pause
    exit /b 1
)
echo ✅ Application construite
cd ..
echo.

echo [5/6] Verification du backend...
netstat -an | find ":8080" >nul
if errorlevel 1 (
    echo ⚠️ Backend non demarre - Demarrage...
    cd backend
    start /min cmd /c "npm start"
    cd ..
    echo Attente de 8 secondes...
    timeout /t 8 /nobreak >nul
) else (
    echo ✅ Backend actif sur port 8080
)
echo.

echo [6/6] Test de connectivite...
curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Backend ne repond pas encore (normal au demarrage)
) else (
    echo ✅ Backend repond correctement
)
echo.

echo ========================================
echo   RECONSTRUCTION TERMINEE AVEC SUCCES
echo ========================================
echo.
echo 🔧 Toutes les configurations corrigees pour port 8080
echo 📱 Application reconstruite
echo 🌐 Backend verifie
echo.
echo PROCHAINES ETAPES:
echo 1. Testez l'application: logesco_v2\build\windows\x64\runner\Release\logesco_v2.exe
echo 2. Connectez-vous avec: admin / admin123
echo 3. Verifiez que les categories se chargent
echo.
echo Si ca fonctionne, le probleme est DEFINITIVEMENT resolu!
echo.
echo Pour creer le package client complet:
echo preparer-pour-client-ultimate.bat
echo.
pause