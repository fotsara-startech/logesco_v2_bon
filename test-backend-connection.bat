@echo off
title LOGESCO - Test Connexion Backend
echo ========================================
echo   TEST CONNEXION BACKEND
echo ========================================
echo.

echo Ce script teste la connexion au backend
echo sur le port 8080.
echo.
pause
echo.

echo [1/4] Verification du port 8080...
netstat -an | find ":8080" >nul
if errorlevel 1 (
    echo ❌ Port 8080 libre - Backend non demarre
    echo.
    echo Demarrez le backend avec:
    echo cd backend
    echo npm start
    echo.
    pause
    exit /b 1
) else (
    echo ✅ Port 8080 occupe - Backend probablement actif
)
echo.

echo [2/4] Test endpoint /health...
curl -s http://localhost:8080/health
if errorlevel 1 (
    echo ❌ Endpoint /health ne repond pas
) else (
    echo ✅ Endpoint /health repond
)
echo.

echo [3/4] Test endpoint /api/v1/categories...
curl -s http://localhost:8080/api/v1/categories
if errorlevel 1 (
    echo ❌ Endpoint /api/v1/categories ne repond pas
) else (
    echo ✅ Endpoint /api/v1/categories repond
)
echo.

echo [4/4] Test avec authentification...
echo Test de connexion avec admin/admin123...
curl -s -X POST http://localhost:8080/api/v1/auth/login -H "Content-Type: application/json" -d "{\"nomUtilisateur\":\"admin\",\"motDePasse\":\"admin123\"}"
if errorlevel 1 (
    echo ❌ Authentification echouee
) else (
    echo ✅ Authentification reussie
)
echo.

echo ========================================
echo   TEST TERMINE
echo ========================================
echo.
echo Si tous les tests passent mais l'app ne fonctionne pas:
echo 1. Verifiez les logs du backend
echo 2. Verifiez que l'app utilise bien localhost:8080
echo 3. Redemarrez l'app Flutter
echo.
pause