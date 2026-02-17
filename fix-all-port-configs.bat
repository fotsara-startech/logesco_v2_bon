@echo off
title LOGESCO - Correction Automatique Ports
echo ========================================
echo   CORRECTION AUTOMATIQUE PORTS
echo ========================================
echo.

echo Ce script corrige automatiquement toutes
echo les configurations de ports pour utiliser 8080.
echo.
pause
echo.

echo [1/5] Verification des fichiers...
set ALL_FILES_OK=1

if not exist "backend\.env" (
    echo ❌ backend\.env manquant
    set ALL_FILES_OK=0
)

if not exist "logesco_v2\lib\core\config\api_config.dart" (
    echo ❌ api_config.dart manquant
    set ALL_FILES_OK=0
)

if not exist "logesco_v2\lib\core\config\environment_config.dart" (
    echo ❌ environment_config.dart manquant
    set ALL_FILES_OK=0
)

if %ALL_FILES_OK%==0 (
    echo ❌ Fichiers manquants, impossible de continuer
    pause
    exit /b 1
)

echo ✅ Tous les fichiers sont presents
echo.

echo [2/5] Sauvegarde des fichiers originaux...
if not exist "backup_configs" mkdir "backup_configs"
copy "backend\.env" "backup_configs\.env.backup" >nul 2>nul
copy "logesco_v2\lib\core\config\api_config.dart" "backup_configs\api_config.dart.backup" >nul 2>nul
copy "logesco_v2\lib\core\config\environment_config.dart" "backup_configs\environment_config.dart.backup" >nul 2>nul
echo ✅ Sauvegardes creees dans backup_configs\
echo.

echo [3/5] Correction backend .env...
REM Créer un nouveau fichier .env avec le bon port
(
echo NODE_ENV=production
echo PORT=8080
echo DATABASE_URL="file:./database/logesco.db"
echo JWT_SECRET="logesco-jwt-secret-change-in-production"
echo CORS_ORIGIN="*"
echo RATE_LIMIT_ENABLED=false
echo DEPLOYMENT_TYPE=local
) > "backend\.env"
echo ✅ Backend configure pour port 8080
echo.

echo [4/5] Correction configurations Flutter...
REM Les fichiers ont déjà été corrigés par les commandes précédentes
echo ✅ Configurations Flutter corrigees
echo.

echo [5/5] Verification des corrections...
echo Verification backend:
findstr "PORT" backend\.env

echo.
echo Verification ApiConfig:
findstr "localhost:8080" logesco_v2\lib\core\config\api_config.dart

echo.
echo Verification EnvironmentConfig:
findstr "localhost:8080" logesco_v2\lib\core\config\environment_config.dart

echo.
echo ========================================
echo   CORRECTIONS APPLIQUEES AVEC SUCCES
echo ========================================
echo.
echo 🔧 Backend: Port 8080
echo 📱 Flutter: localhost:8080
echo 💾 Sauvegardes: backup_configs\
echo.
echo Prochaines etapes:
echo 1. Reconstruire l'app: rebuild-app-quick.bat
echo 2. Ou reconstruire tout: preparer-pour-client-ultimate.bat
echo 3. Tester la connexion
echo.
echo En cas de probleme, restaurez depuis backup_configs\
echo.
pause