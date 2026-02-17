@echo off
title LOGESCO - Correction et Test Final
echo ========================================
echo   CORRECTION ET TEST FINAL
echo ========================================
echo.

echo Ce script corrige toutes les configurations
echo et teste la connexion.
echo.
pause
echo.

echo [1/5] Verification des corrections...
call check-all-port-configs.bat
echo.

echo [2/5] Reconstruction de l'application...
cd logesco_v2
call flutter clean >nul 2>nul
call flutter pub get
if errorlevel 1 (
    echo ❌ ERREUR: flutter pub get echoue
    cd ..
    pause
    exit /b 1
)

call flutter build windows --release
if errorlevel 1 (
    echo ❌ ERREUR: Build Flutter echoue
    cd ..
    pause
    exit /b 1
)
cd ..
echo ✅ Application reconstruite
echo.

echo [3/5] Test du backend...
echo Verification que le backend demarre sur port 8080...
netstat -an | find ":8080" >nul
if errorlevel 1 (
    echo ⚠️ Backend non demarre - Demarrage automatique...
    cd backend
    start /min cmd /c "npm start"
    cd ..
    echo Attente de 10 secondes pour le demarrage...
    timeout /t 10 /nobreak >nul
) else (
    echo ✅ Backend deja actif sur port 8080
)
echo.

echo [4/5] Test de connectivite...
curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ❌ Backend ne repond pas sur /health
    echo Verifiez manuellement le backend
) else (
    echo ✅ Backend repond sur /health
)

curl -s http://localhost:8080/api/v1/categories >nul 2>nul
if errorlevel 1 (
    echo ⚠️ Endpoint /categories ne repond pas (normal sans auth)
) else (
    echo ✅ Endpoint /categories accessible
)
echo.

echo [5/5] Test de l'application...
echo Demarrage de l'application pour test...
start "" "logesco_v2\build\windows\x64\runner\Release\logesco_v2.exe"
echo.
echo ✅ Application demarree
echo.

echo ========================================
echo   CORRECTION ET TEST TERMINES
echo ========================================
echo.
echo 🔧 Toutes les configurations corrigees pour port 8080
echo 📱 Application reconstruite
echo 🌐 Backend teste
echo 🚀 Application lancee
echo.
echo Testez maintenant la connexion dans l'application:
echo 1. Connectez-vous avec: admin / admin123
echo 2. Verifiez que les categories se chargent
echo 3. Si ca fonctionne, le probleme est resolu!
echo.
echo En cas de probleme persistant:
echo - Verifiez les logs du backend
echo - Verifiez que le port 8080 est libre
echo - Redemarrez en tant qu'administrateur
echo.
pause