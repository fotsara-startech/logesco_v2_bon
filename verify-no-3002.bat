@echo off
title LOGESCO - Verification Finale Port 3002
echo ========================================
echo   VERIFICATION FINALE PORT 3002
echo ========================================
echo.

echo Ce script verifie qu'il n'y a plus d'occurrences
echo du port 3002 dans les fichiers critiques.
echo.
pause
echo.

echo [1/7] Verification ApiConfig...
findstr "3002" logesco_v2\lib\core\config\api_config.dart >nul 2>nul
if errorlevel 1 (
    echo ✅ ApiConfig: Aucune occurrence de 3002
) else (
    echo ❌ ApiConfig: Contient encore 3002
    findstr "3002" logesco_v2\lib\core\config\api_config.dart
)
echo.

echo [2/7] Verification EnvironmentConfig...
findstr "3002" logesco_v2\lib\core\config\environment_config.dart >nul 2>nul
if errorlevel 1 (
    echo ✅ EnvironmentConfig: Aucune occurrence de 3002
) else (
    echo ❌ EnvironmentConfig: Contient encore 3002
    findstr "3002" logesco_v2\lib\core\config\environment_config.dart
)
echo.

echo [3/7] Verification InitialBindings...
findstr "3002" logesco_v2\lib\core\bindings\initial_bindings.dart >nul 2>nul
if errorlevel 1 (
    echo ✅ InitialBindings: Aucune occurrence de 3002
) else (
    echo ❌ InitialBindings: Contient encore 3002
    findstr "3002" logesco_v2\lib\core\bindings\initial_bindings.dart
)
echo.

echo [4/7] Verification AppConfig...
findstr "3002" logesco_v2\lib\core\config\app_config.dart >nul 2>nul
if errorlevel 1 (
    echo ✅ AppConfig: Aucune occurrence de 3002
) else (
    echo ❌ AppConfig: Contient encore 3002
    findstr "3002" logesco_v2\lib\core\config\app_config.dart
)
echo.

echo [5/7] Verification LocalConfig...
findstr "3002" logesco_v2\lib\config\local_config.dart >nul 2>nul
if errorlevel 1 (
    echo ✅ LocalConfig: Aucune occurrence de 3002
) else (
    echo ❌ LocalConfig: Contient encore 3002
    findstr "3002" logesco_v2\lib\config\local_config.dart
)
echo.

echo [6/7] Verification BackendService...
findstr "3002" logesco_v2\lib\core\services\backend_service.dart >nul 2>nul
if errorlevel 1 (
    echo ✅ BackendService: Aucune occurrence de 3002
) else (
    echo ❌ BackendService: Contient encore 3002
    findstr "3002" logesco_v2\lib\core\services\backend_service.dart
)
echo.

echo [7/7] Verification SalesService...
findstr "3002" logesco_v2\lib\features\sales\services\sales_service.dart >nul 2>nul
if errorlevel 1 (
    echo ✅ SalesService: Aucune occurrence de 3002
) else (
    echo ❌ SalesService: Contient encore 3002
    findstr "3002" logesco_v2\lib\features\sales\services\sales_service.dart
)
echo.

echo ========================================
echo   VERIFICATION TERMINEE
echo ========================================
echo.
echo RESUME:
echo - Tous les fichiers critiques doivent etre ✅
echo - Si des ❌ apparaissent, corrigez manuellement
echo - Puis executez: rebuild-with-all-fixes.bat
echo.
echo VERIFICATION POSITIVE = Probleme resolu!
echo.
pause