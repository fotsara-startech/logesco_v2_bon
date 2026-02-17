@echo off
title LOGESCO - Diagnostic Pre-Build
echo ========================================
echo   LOGESCO - Diagnostic Pre-Build
echo ========================================
echo.

set ALL_OK=1

echo [1/8] Verification Node.js...
where node >nul 2>nul
if errorlevel 1 (
    echo ❌ Node.js NON INSTALLE
    echo   Telechargez: https://nodejs.org/
    set ALL_OK=0
) else (
    echo ✅ Node.js INSTALLE
    node --version
    
    REM Vérifier la version Node.js
    for /f "tokens=1 delims=v" %%v in ('node --version') do set NODE_VERSION=%%v
    echo   Version: %NODE_VERSION%
)
echo.

echo [2/8] Verification Flutter...
where flutter >nul 2>nul
if errorlevel 1 (
    echo ❌ Flutter NON INSTALLE
    echo   Telechargez: https://flutter.dev/
    set ALL_OK=0
) else (
    echo ✅ Flutter INSTALLE
    flutter --version | findstr "Flutter"
)
echo.

echo [3/8] Verification des dependances backend...
if exist "backend\node_modules" (
    echo ✅ node_modules backend present
) else (
    echo ⚠️ node_modules backend manquant
    echo   Executez: cd backend && npm install
)

if exist "backend\node_modules\.prisma" (
    echo ✅ Client Prisma present
) else (
    echo ⚠️ Client Prisma manquant
    echo   Executez: cd backend && npx prisma generate
)
echo.

echo [4/8] Verification des dependances Flutter...
if exist "logesco_v2\pubspec.lock" (
    echo ✅ pubspec.lock present
) else (
    echo ⚠️ pubspec.lock manquant
    echo   Executez: cd logesco_v2 && flutter pub get
)
echo.

echo [5/8] Verification de l'espace disque...
for /f "tokens=3" %%a in ('dir /-c ^| find "bytes free"') do set FREE_SPACE=%%a
if defined FREE_SPACE (
    echo ✅ Espace libre detecte
) else (
    echo ⚠️ Impossible de detecter l'espace libre
)
echo.

echo [6/8] Verification des processus en cours...
tasklist | find "node.exe" >nul
if errorlevel 1 (
    echo ✅ Aucun processus Node.js actif
) else (
    echo ⚠️ Processus Node.js detectes
    echo   Fermez les processus Node.js avant le build
    tasklist | find "node.exe"
)
echo.

echo [7/8] Verification du port 8080...
netstat -an | find ":8080" >nul
if errorlevel 1 (
    echo ✅ Port 8080 libre
) else (
    echo ⚠️ Port 8080 occupe
    echo   Fermez l'application utilisant le port 8080
)
echo.

echo [8/8] Verification des dossiers de build...
if exist "dist-portable" (
    echo ⚠️ Dossier dist-portable existe
    echo   Sera nettoye automatiquement
) else (
    echo ✅ Pas de dossier dist-portable
)

if exist "release\LOGESCO-Client" (
    echo ⚠️ Dossier release\LOGESCO-Client existe
    echo   Sera nettoye automatiquement
) else (
    echo ✅ Pas de dossier release existant
)
echo.

echo ========================================
if %ALL_OK%==1 (
    echo   ✅ SYSTEME PRET POUR LE BUILD
    echo ========================================
    echo.
    echo Vous pouvez maintenant executer:
    echo   preparer-pour-client-fixed.bat
    echo.
    echo Ou pour un build backend uniquement:
    echo   cd backend
    echo   node build-portable-fixed.js
) else (
    echo   ❌ PROBLEMES DETECTES
    echo ========================================
    echo.
    echo Corrigez les problemes ci-dessus avant
    echo de lancer le build.
    echo.
    echo Solutions rapides:
    echo   - Installer Node.js: https://nodejs.org/
    echo   - Installer Flutter: https://flutter.dev/
    echo   - Installer dependances: npm install
    echo   - Fermer processus: taskkill /f /im node.exe
)
echo ========================================
echo.
pause