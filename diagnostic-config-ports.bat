@echo off
title LOGESCO - Diagnostic Configuration Ports
echo ========================================
echo   DIAGNOSTIC CONFIGURATION PORTS
echo ========================================
echo.

echo Ce script verifie toutes les configurations
echo de ports dans le projet LOGESCO.
echo.
pause
echo.

echo [1/4] Verification backend (.env)...
if exist "backend\.env" (
    echo ✅ Fichier backend\.env trouve
    echo Contenu PORT:
    findstr "PORT" backend\.env
    echo.
) else (
    echo ❌ Fichier backend\.env manquant
)

echo [2/4] Verification ApiConfig (Flutter)...
if exist "logesco_v2\lib\core\config\api_config.dart" (
    echo ✅ Fichier api_config.dart trouve
    echo Configuration baseUrl:
    findstr "baseUrl.*localhost" logesco_v2\lib\core\config\api_config.dart
    echo.
) else (
    echo ❌ Fichier api_config.dart manquant
)

echo [3/4] Verification EnvironmentConfig (Flutter)...
if exist "logesco_v2\lib\core\config\environment_config.dart" (
    echo ✅ Fichier environment_config.dart trouve
    echo Configuration apiBaseUrl:
    findstr "localhost" logesco_v2\lib\core\config\environment_config.dart
    echo.
) else (
    echo ❌ Fichier environment_config.dart manquant
)

echo [4/4] Test de connectivite...
echo Test du port 8080...
netstat -an | find ":8080" >nul
if errorlevel 1 (
    echo ⚠️ Port 8080 libre (backend non demarre)
) else (
    echo ✅ Port 8080 occupe (backend probablement actif)
)

echo Test du port 3002...
netstat -an | find ":3002" >nul
if errorlevel 1 (
    echo ✅ Port 3002 libre (bon)
) else (
    echo ⚠️ Port 3002 occupe (conflit possible)
)

echo.
echo Test de connexion HTTP...
curl -s http://localhost:8080/health >nul 2>nul
if errorlevel 1 (
    echo ❌ Backend sur port 8080 ne repond pas
    echo   Demarrez le backend avec: cd backend && npm start
) else (
    echo ✅ Backend sur port 8080 repond correctement
)

echo.
echo ========================================
echo   DIAGNOSTIC TERMINE
echo ========================================
echo.
echo RESUME:
echo - Backend doit etre sur port 8080
echo - Flutter doit pointer vers localhost:8080
echo - Aucun service ne doit utiliser le port 3002
echo.
echo Si probleme persiste:
echo 1. Verifiez que le backend demarre sur port 8080
echo 2. Reconstruisez l'app Flutter: rebuild-app-quick.bat
echo 3. Testez la connexion manuellement
echo.
pause