@echo off
title LOGESCO - Verification Complete Ports
echo ========================================
echo   VERIFICATION COMPLETE PORTS
echo ========================================
echo.

echo Ce script verifie TOUTES les configurations
echo de ports dans le projet LOGESCO.
echo.
pause
echo.

echo [1/6] Backend .env...
if exist "backend\.env" (
    echo ✅ backend\.env
    findstr "PORT" backend\.env | findstr /V "REM"
) else (
    echo ❌ backend\.env manquant
)
echo.

echo [2/6] ApiConfig (Flutter)...
if exist "logesco_v2\lib\core\config\api_config.dart" (
    echo ✅ api_config.dart
    findstr "localhost" logesco_v2\lib\core\config\api_config.dart
) else (
    echo ❌ api_config.dart manquant
)
echo.

echo [3/6] EnvironmentConfig (Flutter)...
if exist "logesco_v2\lib\core\config\environment_config.dart" (
    echo ✅ environment_config.dart
    findstr "localhost" logesco_v2\lib\core\config\environment_config.dart
) else (
    echo ❌ environment_config.dart manquant
)
echo.

echo [4/6] InitialBindings (Flutter)...
if exist "logesco_v2\lib\core\bindings\initial_bindings.dart" (
    echo ✅ initial_bindings.dart
    findstr "localhost" logesco_v2\lib\core\bindings\initial_bindings.dart
) else (
    echo ❌ initial_bindings.dart manquant
)
echo.

echo [5/6] ServiceLocator (Flutter)...
if exist "logesco_v2\lib\core\services\service_locator.dart" (
    echo ✅ service_locator.dart
    findstr "ApiConfig.currentBaseUrl" logesco_v2\lib\core\services\service_locator.dart
) else (
    echo ❌ service_locator.dart manquant
)
echo.

echo [6/6] Recherche autres occurrences de 3002...
echo Recherche dans tous les fichiers Dart:
findstr /S /N "3002" logesco_v2\lib\*.dart 2>nul
if errorlevel 1 (
    echo ✅ Aucune occurrence de 3002 trouvee
) else (
    echo ⚠️ Occurrences de 3002 trouvees ci-dessus
)
echo.

echo ========================================
echo   VERIFICATION TERMINEE
echo ========================================
echo.
echo RESUME ATTENDU:
echo - Backend: PORT=8080
echo - ApiConfig: localhost:8080
echo - EnvironmentConfig: localhost:8080  
echo - InitialBindings: localhost:8080
echo - ServiceLocator: ApiConfig.currentBaseUrl
echo - Aucune occurrence de 3002
echo.
echo Si des problemes sont detectes:
echo 1. Corrigez manuellement les fichiers
echo 2. Ou executez: fix-all-port-configs.bat
echo 3. Puis reconstruisez: rebuild-app-quick.bat
echo.
pause